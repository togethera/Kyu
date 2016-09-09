//
//  KyuViewModel.swift
//  Kyu
//
//  Created by Red Davis on 21/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import Foundation


public final class KyuViewModel
{
    // Public
    public let workers: [KyuWorkerViewModel]
    
    // Private
    private let kyu: Kyu
    
    // MARK: Initialization
    
    public init(kyu: Kyu)
    {
        self.kyu = kyu
        
        self.workers = kyu.workers.map({ (worker) -> KyuWorkerViewModel in
            return KyuWorkerViewModel(worker: worker)
        })
    }
}
