//
//  KyuPerformanceTest.swift
//  Kyu
//
//  Created by Red Davis on 06/12/2015.
//  Copyright © 2015 Red Davis. All rights reserved.
//

import XCTest
import Kyu


class KyuPerformanceTest: XCTestCase
{
    // Basic job
    
    func testTwoThreadsTwoHundredJobs()
    {
        let kyu = try! Kyu.configure { (config: KyuConfiguration) -> () in
            config.numberOfWorkers = 2
            config.directoryURL = self.randomQueueURL()
            config.job = TestJob()
        }
        
        kyu.paused = true
        
        for _ in 1...200
        {
            kyu.queueJob(["1":2, "3":4])
        }
        
        kyu.paused = false
        
        self.measureBlock { () -> Void in
            while kyu.numberOfJobs > 0 { }
        }
    }
    
    func testFourThreadsTwoHundredJobs()
    {
        let kyu = try! Kyu.configure { (config: KyuConfiguration) -> () in
            config.numberOfWorkers = 4
            config.directoryURL = self.randomQueueURL()
            config.job = TestJob()
        }
        
        kyu.paused = true
        
        for _ in 1...200
        {
            kyu.queueJob(["1":2, "3":4])
        }
        
        kyu.paused = false
        
        self.measureBlock { () -> Void in
            while kyu.numberOfJobs > 0 { }
        }
    }
    
    func testEightThreadsTwoHundredJobs()
    {
        let kyu = try! Kyu.configure { (config: KyuConfiguration) -> () in
            config.numberOfWorkers = 8
            config.directoryURL = self.randomQueueURL()
            config.job = TestJob()
        }
        
        kyu.paused = true
        
        for _ in 1...200
        {
            kyu.queueJob(["1":2, "3":4])
        }
        
        kyu.paused = false
        
        self.measureBlock { () -> Void in
            while kyu.numberOfJobs > 0 { }
        }
    }
    
    // MARK: Helpers
    
    private func randomQueueURL() -> NSURL
    {
        return NSURL(string: NSTemporaryDirectory() + "\(arc4random())\(arc4random())")!
    }
}
