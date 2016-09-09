//
//  KyuJobTests.swift
//  Kyu
//
//  Created by Red Davis on 09/02/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import XCTest
@testable import Kyu


class KyuJobTests: XCTestCase
{
    // Private
    private var testJobURL: NSURL!
    
    // MARK: Setup
    
    override func setUp()
    {
        super.setUp()
        
        self.testJobURL = self.createTestJob()
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    // MARK: Retry count
    
    func testRetryCountIncreases()
    {
        let job = try! KyuJob(directoryURL: self.testJobURL)
        
        XCTAssertEqual(job.numberOfRetries, 0)
        
        job.incrementRetryCount()
        job.incrementRetryCount()
        job.incrementRetryCount()
        
        XCTAssertEqual(job.numberOfRetries, 3)
    }
    
    // MARK: Incrementing process date
    
    func testProcessDateIncreases()
    {
        let job = try! KyuJob(directoryURL: self.testJobURL)
        let originalProcessDate = job.processDate
        
        job.incrementRetryCount()
        job.incrementRetryCount()
        job.incrementRetryCount()
        
        let originalIsDateEarlier = originalProcessDate.compare(job.processDate) == .OrderedAscending
        XCTAssert(originalIsDateEarlier)
    }
    
    // MARK: Helpers
    
    private func createTestJob() -> NSURL
    {
        let directoryName = NSUUID().UUIDString
        let directoryPath = NSTemporaryDirectory() + directoryName
        
        let fileManager = NSFileManager.defaultManager()
        
        try! fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
        
        let directoryPathURL = NSURL(fileURLWithPath: directoryPath)
        let identifier = NSUUID().UUIDString
        KyuJob.createJob(identifier, arguments: ["test" : "test"], queueDirectoryURL: directoryPathURL)
        
        let jobDirectoryName = try! fileManager.contentsOfDirectoryAtPath(directoryPath).first!
        
        return directoryPathURL.URLByAppendingPathComponent(jobDirectoryName)
    }
}
