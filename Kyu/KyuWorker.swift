//
//  KyuThread.swift
//  Kyu
//
//  Created by Red Davis on 14/11/2015.
//  Copyright © 2015 Red Davis. All rights reserved.
//

import Foundation


internal protocol KyuWorkerDataSource
{
    func workerShouldIncrementRetryCounts() -> Bool
    func jobForKyuWorker(worker: KyuWorker) -> KyuJobProtocol
    func baseTemporaryDirectoryForKyuWorker(worker: KyuWorker) -> NSURL
    func baseJobDirectoryForKyuWorker(worker: KyuWorker) -> NSURL
    func maximumNumberOfRetriesForKyuWorker(worker: KyuWorker) -> Int
}


internal protocol KyuWorkerDelegate
{
    func worker(worker: KyuWorker, didStartProcessingJob job: KyuJob)
    func worker(worker: KyuWorker, didFinishProcessingJob job: KyuJob, withResult result: KyuJobResult)
}


/**
 KyuConfigurationError
 */
public enum KyuWorkerInitializationError: ErrorType
{
    case errorCreatingWorkerDirectory
}


final internal class KyuWorker
{
    internal let identifier: String
    
    internal var delegate: KyuWorkerDelegate?
    
    internal var paused = false {
        didSet
        {
            if !self.paused
            {
                self.processNextJob()
            }
        }
    }
    
    internal var numberOfJobs: Int {
        let fileManager = NSFileManager.defaultManager()
        
        var numberOfJobs = 0
        do
        {
            let jobs = try fileManager.contentsOfDirectoryAtPath(self.queueDirectoryPathURL.path!)
            numberOfJobs = jobs.count
        }
        catch { }
        
        return numberOfJobs
    }
    
    // Private
    private let dataSource: KyuWorkerDataSource
    
    // Queue management
    private var queueDirectoryPathURL: NSURL {
        let baseURL = self.dataSource.baseJobDirectoryForKyuWorker(self)
        return baseURL.URLByAppendingPathComponent(self.identifier)
    }
    
    private let checkJobsTimerQueue: dispatch_queue_t
    
    private let queueDirectoryObserverQueue: dispatch_queue_t
    private var queueDirectoryObserver: dispatch_source_t!
    private let queueDirectoryOperationQueue = NSOperationQueue()
    private var isProcessing = false
    
    private let jobProcessingOperationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        return operationQueue
    }()
    
    private let jobFetchingOperationQueue = NSOperationQueue()
    
    private var currentJob: KyuJob?
    
    // JSON
    private let JSONFilename = "JSON"
    
    // Temporary directory
    private var temporaryDirectoryPathURL: NSURL {
        let baseTemporaryDirectoryURL = self.dataSource.baseTemporaryDirectoryForKyuWorker(self)
        return baseTemporaryDirectoryURL.URLByAppendingPathComponent(self.identifier)
    }
    
    // Workers
    private var worker: KyuJobProtocol {
        return self.dataSource.jobForKyuWorker(self)
    }
    
    // Retry
    private var maximumNumberOfRetries: Int {
        return self.dataSource.maximumNumberOfRetriesForKyuWorker(self)
    }
    
    // MARK: Initialization
    
    internal required init(identifier: String, dataSource: KyuWorkerDataSource) throws
    {
        self.identifier = identifier
        self.dataSource = dataSource
        
        self.checkJobsTimerQueue = dispatch_queue_create("com.kyu.\(self.identifier)-check-jobs", nil)
        self.queueDirectoryObserverQueue = dispatch_queue_create("com.kyu.\(self.identifier)", nil)
        
        // Create directories
        do
        {
            try self.setupTemporaryDirectory()
            try self.setupQueueDirectory()
        }
        catch
        {
            throw KyuWorkerInitializationError.errorCreatingWorkerDirectory
        }
        
        // Queue directory observer
        let directoryFileDescriptor = UInt(open(self.queueDirectoryPathURL.fileSystemRepresentation, O_EVTONLY))
        self.queueDirectoryObserver = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, directoryFileDescriptor, DISPATCH_VNODE_WRITE, self.queueDirectoryObserverQueue)
        
        dispatch_source_set_event_handler(self.queueDirectoryObserver, { [weak self] () -> Void in
            if let weakSelf = self
            {
                weakSelf.queueDirectoryUpdated()
            }
        })
        
        dispatch_resume(self.queueDirectoryObserver)
        
        // Check queue timer
        self.dispatchCheckJobsQueue()
        
        // Process next job
        self.processNextJob()
    }
    
    deinit
    {
    
    }
    
    // MARK: Job management
    
    internal func cancelJob(identifier: String) -> Bool
    {
        let job = self.fetchAllJobs().filter { (job) -> Bool in
            return job.identifier == identifier && self.currentJob?.identifier != job.identifier
        }.first
        
        guard let unwrappedJob = job else
        {
            return false
        }

        unwrappedJob.delete()
        return true
    }
    
    internal func queueJob(arguments: KyuJobArguments) -> String
    {
        let jobIdentifier = NSUUID().UUIDString
        
        self.queueDirectoryOperationQueue.addOperationWithBlock { () -> Void in
            // Create job
            KyuJob.createJob(jobIdentifier, arguments: arguments, queueDirectoryURL: self.queueDirectoryPathURL)
            self.processNextJob()
        }
        
        return jobIdentifier
    }
    
    private func processNextJob()
    {
        if self.isProcessing || self.paused
        {
            return
        }
        
        self.isProcessing = true
        
        self.jobProcessingOperationQueue.addOperationWithBlock { [weak self] () -> Void in
            guard let weakSelf = self else { return }
            
            if let nextJob = weakSelf.nextJobToProcess()
            {
                weakSelf.currentJob = nextJob
                
                // Update delegate
                weakSelf.delegate?.worker(weakSelf, didStartProcessingJob: nextJob)
                
                // Execute job
                let result = weakSelf.worker.perform(nextJob.JSON)
                let shouldIncrementRetryCount = self?.dataSource.workerShouldIncrementRetryCounts() ?? true
                
                switch result
                {
                    case .success:
                        nextJob.delete()
                    case .fail where shouldIncrementRetryCount:
                        if nextJob.numberOfRetries >= weakSelf.maximumNumberOfRetries
                        {
                            nextJob.delete()
                        }
                        else
                        {
                            nextJob.incrementRetryCount()
                        }
                    default:()
                }
                
                // Update delegate
                weakSelf.delegate?.worker(weakSelf, didFinishProcessingJob: nextJob, withResult: result)
                
                // Process next job!
                weakSelf.isProcessing = false
                weakSelf.processNextJob()
            }
            else
            {
                weakSelf.isProcessing = false
            }
        }
    }
    
    // MARK: -
    
    /**
     If no jobs are added and therefore directory not touched, then jobs
     whose process data are in the future will not be processed until
     something new is added to the queue.
     */
    private func dispatchCheckJobsQueue()
    {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(20.0 * Double(NSEC_PER_SEC)))
        dispatch_after(time, self.checkJobsTimerQueue) { [weak self] in
            self?.processNextJob()
            self?.dispatchCheckJobsQueue()
        }
    }
    
    // MARK: -
    
    private func queueDirectoryUpdated()
    {
        self.processNextJob()
    }
    
    // MARK: Jobs
    
    private func nextJobToProcess() -> KyuJob?
    {
        let jobs = self.fetchAllJobs()
        return jobs.first
    }
    
    private func fetchAllJobs() -> [KyuJob]
    {
        let fileManager = NSFileManager.defaultManager()
        guard let jobDirectoryNames = (try? fileManager.contentsOfDirectoryAtPath(self.queueDirectoryPathURL.path!)) else
        {
            return []
        }
        
        let jobs = jobDirectoryNames.flatMap({ (directoryName) -> NSURL? in
            return self.queueDirectoryPathURL.URLByAppendingPathComponent(directoryName)
        }).flatMap({ (directoryURL) -> KyuJob? in
            do
            {
                let job = try KyuJob(directoryURL: directoryURL)
                return job
            }
            catch
            {
                return nil
            }
        }).filter({ (job) -> Bool in
            return job.shouldProcess
        }).sort({ (jobA, jobB) -> Bool in
            return jobA.processDate.compare(jobB.processDate) == .OrderedAscending
        })
        
        return jobs
    }
    
    internal func requestAllJobs(completionHandler: (jobs: [KyuJob]) -> Void)
    {
        self.jobFetchingOperationQueue.addOperationWithBlock { [weak self] in
            guard let weakSelf = self else { return }
            
            let jobs = weakSelf.fetchAllJobs()
            completionHandler(jobs: jobs)
        }
    }
    
    // MARK: File system
    
    private func setupQueueDirectory() throws
    {
        try self.createDirectoryAtPath(self.queueDirectoryPathURL.path!)
    }
    
    private func setupTemporaryDirectory() throws
    {
        try self.createDirectoryAtPath(self.temporaryDirectoryPathURL.path!)
    }
    
    private func createDirectoryAtPath(directoryPath: String) throws
    {
        let fileManager = NSFileManager.defaultManager()
        
        var isDirectory: ObjCBool = false
        if fileManager.fileExistsAtPath(directoryPath, isDirectory: &isDirectory)
        {
            if !isDirectory
            {
                // TODO: raise error?
            }
        }
        else
        {
            try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
