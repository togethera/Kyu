//
//  KyuWorkerViewModel.swift
//  Kyu
//
//  Created by Red Davis on 21/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import Foundation


public final class KyuWorkerViewModel
{
    // Public
    public let identifier: String
    public let paused: Bool
    public let numberOfJobs: Int
    
    // Private
    private let worker: KyuWorker
    
    // MARK: Initialization
    
    internal init(worker: KyuWorker)
    {
        self.worker = worker
        self.identifier = worker.identifier
        self.paused = worker.paused
        self.numberOfJobs = worker.numberOfJobs
    }
    
    // MARK: Fetch jobs
    
    public func requestAllJobs(completionHandler: (jobs: [KyuJobViewModel]) -> Void)
    {
        self.worker.requestAllJobs { (jobs) in
            let jobViewModels = jobs.map({ (job) -> KyuJobViewModel in
                return KyuJobViewModel(job: job)
            })
            
            completionHandler(jobs: jobViewModels)
        }
    }
}
