//
//  KyuTests.swift
//  KyuTests
//
//  Created by Red Davis on 14/06/2015.
//  Copyright (c) 2015 Red Davis. All rights reserved.
//

import XCTest
import Kyu


// MARK: - Test Worker

class TestJob: KyuJobProtocol
{
    func perform(arguments: [String : AnyObject]) -> KyuJobResult
    {
        return KyuJobResult.success
    }
}

class FailingTestJob: KyuJobProtocol
{
    func perform(arguments: [String : AnyObject]) -> KyuJobResult
    {
        return KyuJobResult.fail
    }
}

// MARK: - New Line Worker

class NewLineJob: KyuJobProtocol
{
    static let filePathArgumentKey = "filePath"
    
    func perform(arguments: [String : AnyObject]) -> KyuJobResult
    {
        guard let filePath = arguments[NewLineJob.filePathArgumentKey] as? String,
              let fileHandle = NSFileHandle(forWritingAtPath: filePath) else
        {
            return KyuJobResult.fail
        }
        
        let stringToWrite = "Hello\n"
        let stringToWriteData = stringToWrite.dataUsingEncoding(NSUTF8StringEncoding)!
        
        fileHandle.seekToEndOfFile()
        fileHandle.writeData(stringToWriteData)
        fileHandle.closeFile()
        
        return KyuJobResult.success
    }
}


class KyuTests: XCTestCase, KyuDataSource
{
    private var kyu: Kyu!
    private let operationQueue = NSOperationQueue()
    private var shouldIncrementRetryCount = true
    
    // MARK: Setup
    
    override func setUp()
    {
        super.setUp()
        
        self.shouldIncrementRetryCount = true
        
        let kyuQueueURL = self.randomQueueURL()
        self.kyu = try! Kyu(numberOfWorkers: 4, job: TestJob(), directoryURL: kyuQueueURL, maximumNumberOfRetries: 0)
    }
    
    // MARK: Tests
    
    func testInitializationHelper()
    {
        do
        {
            let _ = try Kyu.configure { (config: KyuConfiguration) -> () in
                config.numberOfWorkers = 1
                config.directoryURL = self.randomQueueURL()
                config.job = TestJob()
            }
        }
        catch let error
        {
            XCTFail("Invalid error raised \(error)")
        }
    }
    
    func testErrorRaisedWithInvalidNumberOfThreads()
    {
        do
        {
            let _ = try Kyu(numberOfWorkers: 0, job: TestJob(), directoryURL: self.randomQueueURL(), maximumNumberOfRetries: 0)
            XCTFail("KyuError.InvalidNumberOfThreads should have been raised")
        }
        catch KyuError.invalidNumberOfWorkers
        {
            XCTAssert(true)
        }
        catch
        {
            XCTFail("Wrong error raised")
        }
    }
    
    func testKyuCountingJobs()
    {
        self.kyu.paused = true
        self.kyu.queueJob(["1":2, "3":4])
        self.kyu.queueJob(["1":2, "3":4])
        self.kyu.queueJob(["1":2, "3":4])
        
        let expectation = self.expectationWithDescription("check number of jobs")
        self.operationQueue.addOperationWithBlock { () -> Void in
            while true
            {
                if self.kyu.numberOfJobs == 3
                {
                    expectation.fulfill()
                    break
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testOutputShouldContain4NewLines()
    {
        // Create temp file
        let resultFileDirectoryPath = self.randomQueueURL().path!
        let resultFilePath = resultFileDirectoryPath + "/result.txt"
        
        try! NSFileManager.defaultManager().createDirectoryAtPath(resultFileDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        NSFileManager.defaultManager().createFileAtPath(resultFilePath, contents: nil, attributes: nil)
        
        // Setup Kyu
        let queueURL = self.randomQueueURL()
        let newLineKyu = try! Kyu(numberOfWorkers: 4, job: NewLineJob(), directoryURL: queueURL, maximumNumberOfRetries: 0)
        
        newLineKyu.queueJob([NewLineJob.filePathArgumentKey:resultFilePath])
        newLineKyu.queueJob([NewLineJob.filePathArgumentKey:resultFilePath])
        newLineKyu.queueJob([NewLineJob.filePathArgumentKey:resultFilePath])
        
        let expectation = self.expectationWithDescription("write all lines")
        
        self.operationQueue.addOperationWithBlock { () -> Void in
            sleep(1) // Give time to write data to disc :/
            
            while true
            {
                if newLineKyu.numberOfJobs == 0
                {
                    let resultFileData = NSData(contentsOfFile: resultFilePath)!
                    let resultString = NSString(data: resultFileData, encoding: NSUTF8StringEncoding)!
                    
                    let resultLines = resultString.componentsSeparatedByString("\n")
                    XCTAssertEqual(resultLines.count, 4)
                    
                    expectation.fulfill()
                    break
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
    func testNotIncrementingRetryCount()
    {
        self.shouldIncrementRetryCount = false
        
        // Setup Kyu
        let queueURL = self.randomQueueURL()
        let kyu = try! Kyu(numberOfWorkers: 4, job: FailingTestJob(), directoryURL: queueURL, maximumNumberOfRetries: 0)
        kyu.dataSource = self
        
        // Add job
        kyu.queueJob(["1":2])
        
        let expectation = self.expectationWithDescription("shouldn't delete job")
        
        self.operationQueue.addOperationWithBlock { () -> Void in
            sleep(1) // Give time to write data to disc :/
            
            XCTAssertEqual(kyu.numberOfJobs, 1)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
    // MARK: Cancelling jobs
    
    func testCancellingJob()
    {
        self.kyu.paused = true
        
        // Add job
        let jobIdentifier = self.kyu.queueJob(["1":2])
        
        let expectation = self.expectationWithDescription("cancel job")
        
        self.operationQueue.addOperationWithBlock { () -> Void in
            sleep(1) // Give time to write data to disc :/
            
            XCTAssertEqual(self.kyu.numberOfJobs, 1)
            
            try! self.kyu.cancelJob(jobIdentifier)
            
            XCTAssertEqual(self.kyu.numberOfJobs, 0)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
    func testCancellingJobThatDoesntExist()
    {
        do
        {
            try self.kyu.cancelJob("i made this up")
            XCTFail("KyuJobManagementError.JobNotFound should have been raised")
        }
        catch KyuJobManagementError.jobNotFound
        {
            XCTAssert(true)
        }
        catch
        {
            XCTFail("Wrong error raised")
        }
    }
    
    // MARK: Helpers
    
    private func randomQueueURL() -> NSURL
    {
        return NSURL(string: NSTemporaryDirectory() + "\(arc4random())\(arc4random())")!
    }
    
    // MARK: KyuDataSource
    
    func kyuShouldIncrementRetryCount() -> Bool
    {
        return self.shouldIncrementRetryCount
    }
}
