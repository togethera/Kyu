//
//  KyuJob.swift
//  Kyu
//
//  Created by Red Davis on 09/01/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import Foundation


internal enum KyuJobError: ErrorType
{
    case JSONFileNotFound
    case invalidJSON
}


internal final class KyuJob
{
    private static let JSONFileName = "JSON"
    
    /**
     Use this method to create a job. It firstly creates the jobs directory structure
     in a temporary directory and then moves it to the queue directory specified
     
     - parameter arguments:    Job arguments
     - parameter queueDirectoryURL: The queue directory URL
     */
    internal class func createJob(identifier: String, arguments: [String : AnyObject], queueDirectoryURL: NSURL)
    {
        let fileManager = NSFileManager.defaultManager()
        
        // Temporary directory
        let temporaryDirectory = NSURL(string: NSTemporaryDirectory())!
        let kyuTemporaryDirectory = temporaryDirectory.URLByAppendingPathComponent("KyuTemp")
        
        // Create job in temporary directory
        let jobTemporaryDirectoryURL = kyuTemporaryDirectory.URLByAppendingPathComponent(identifier)
        try! fileManager.createDirectoryAtPath(jobTemporaryDirectoryURL.path!, withIntermediateDirectories: true, attributes: nil)
        
        // Write JSON
        let JSONFileURL = jobTemporaryDirectoryURL.URLByAppendingPathComponent(KyuJob.JSONFileName)
        
        let JSONData = try! NSJSONSerialization.dataWithJSONObject(arguments, options: [])
        JSONData.writeToFile(JSONFileURL.path!, atomically: true)
        
        // Move Job to the queue directory
        let jobDirectoryURL = queueDirectoryURL.URLByAppendingPathComponent(identifier)
        try! fileManager.moveItemAtPath(jobTemporaryDirectoryURL.path!, toPath: jobDirectoryURL.path!)
    }
    
    // Internal
    internal let JSON: [String : AnyObject]
    
    internal var processDate: NSDate {
        guard let directoryAttributes = try? fileManager.attributesOfItemAtPath(self.directoryURL.path!),
            let modifiedDate = directoryAttributes[NSFileModificationDate] as? NSDate else
        {
            return NSDate()
        }
        
        return modifiedDate
    }
    
    internal var shouldProcess: Bool {
        let nowDate = NSDate()
        return self.processDate.compare(nowDate) == NSComparisonResult.OrderedAscending
    }
    
    internal var numberOfRetries: Int {
        var numberOfRetries = 0
        do
        {
            let retries = try self.fileManager.contentsOfDirectoryAtPath(self.retryAttemptDirectoryURL.path!)
            numberOfRetries = retries.count
        }
        catch { }
        
        return numberOfRetries
    }
    
    internal var identifier: String {
        return self.directoryURL.lastPathComponent!
    }
    
    // Private
    private let fileManager = NSFileManager.defaultManager()
    private let directoryURL: NSURL
    
    private let retryAttemptDirectoryName = "retries"
    private let retryAttemptDirectoryURL: NSURL
    
    // MARK: Initialization
    
    internal required init(directoryURL: NSURL) throws
    {
        self.directoryURL = directoryURL
        self.retryAttemptDirectoryURL = self.directoryURL.URLByAppendingPathComponent(self.retryAttemptDirectoryName, isDirectory: true)
        
        let JSONURL = directoryURL.URLByAppendingPathComponent(KyuJob.JSONFileName)
        guard let JSONURLPath = JSONURL.path else { throw KyuJobError.JSONFileNotFound }
        
        guard let JSONData = NSData(contentsOfFile: JSONURLPath) else
        {
            throw KyuJobError.JSONFileNotFound
        }
        
        guard let JSON = (try NSJSONSerialization.JSONObjectWithData(JSONData, options: [])) as? [String : AnyObject] else
        {
            throw KyuJobError.invalidJSON
        }
        
        self.JSON = JSON
    }
    
    // MARK: -
    
    internal func delete()
    {
        do
        {
            try self.fileManager.removeItemAtPath(self.directoryURL.path!)
        }
        catch
        {
            // Directory has been deleted?
        }
    }
    
    // MARK: Retries
    
    internal func incrementRetryCount()
    {
        if !self.retryDirectoryExists()
        {
            do
            {
                try self.createRetryDirectory()
            }
            catch
            {
                
            }
        }
        
        let retryFileName = NSUUID().UUIDString
        let retryFileURL = self.retryAttemptDirectoryURL.URLByAppendingPathComponent(retryFileName)
        self.fileManager.createFileAtPath(retryFileURL.path!, contents: nil, attributes: nil)
        
        self.setNextRetryDate()
    }
    
    private func setNextRetryDate()
    {
        do
        {
            let numberOfRetries = Double(self.numberOfRetries)
            let delta = 3.0
            let seconds = 30.0
            
            let retryTimeInterval = seconds * pow(numberOfRetries, delta)
            let retryDate = NSDate().dateByAddingTimeInterval(retryTimeInterval)
            
            let attributes = [NSFileModificationDate: retryDate]
            
            let directoryPath = self.directoryURL.path!
            try self.fileManager.setAttributes(attributes, ofItemAtPath: directoryPath)
        }
        catch
        {
            // TODO: ?
        }
    }
    
    // MARK: -
    
    private func retryDirectoryExists() -> Bool
    {
        return self.fileManager.fileExistsAtPath(self.retryAttemptDirectoryURL.path!)
    }
    
    private func createRetryDirectory() throws
    {
        try self.fileManager.createDirectoryAtPath(self.retryAttemptDirectoryURL.path!, withIntermediateDirectories: true, attributes: nil)
    }
}
