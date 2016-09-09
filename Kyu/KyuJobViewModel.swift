//
//  KyuJobViewModel.swift
//  Kyu
//
//  Created by Red Davis on 23/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import Foundation


public final class KyuJobViewModel
{
    public let identifier: String
    public let numberOfRetries: Int
    public let JSON: [String : AnyObject]
    
    // Private
    private let job: KyuJob
    
    // MARK: Initialization
    
    internal init(job: KyuJob)
    {
        self.job = job
        self.identifier = job.identifier
        self.numberOfRetries = job.numberOfRetries
        self.JSON = job.JSON
    }
}
