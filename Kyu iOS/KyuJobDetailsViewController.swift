//
//  KyuJobDetailsViewController.swift
//  Kyu
//
//  Created by Red Davis on 29/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import UIKit


internal class KyuJobDetailsViewController: UIViewController
{
    // Private
    private let job: KyuJobViewModel!
    
    private let textView = UITextView()
    
    // MARK: Initialization
    
    internal required init(job: KyuJobViewModel)
    {
        self.job = job
        super.init(nibName: nil, bundle: nil)
    }
    
    internal required init?(coder aDecoder: NSCoder)
    {
        self.job = nil
        super.init(coder: aDecoder)
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = self.job.identifier
        
        // Text view
        self.textView.editable = false
        self.textView.showsVerticalScrollIndicator = true
        self.textView.alwaysBounceVertical = true
        self.view.addSubview(self.textView)
        
        // JSON
        do
        {
            let JSONData = try NSJSONSerialization.dataWithJSONObject(self.job.JSON, options: .PrettyPrinted)
            let JSONString = String(data: JSONData, encoding: NSUTF8StringEncoding)
            
            self.textView.text = JSONString
        }
        catch { }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        self.textView.frame = self.view.bounds
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}
