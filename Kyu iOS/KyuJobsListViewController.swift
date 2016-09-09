//
//  KyuJobsListViewController.swift
//  Kyu
//
//  Created by Red Davis on 21/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import UIKit


internal class KyuJobsListViewController: UIViewController, UITableViewDataSource,
                                        UITableViewDelegate
{
    // Private
    private let worker: KyuWorkerViewModel!
    private var jobs = [KyuJobViewModel]() {
        didSet
        {
            self.tableView.reloadData()
        }
    }
    
    private let tableView = UITableView(frame: CGRect.zero, style: .Plain)
    
    // MARK: Initialization
    
    internal required init(worker: KyuWorkerViewModel)
    {
        self.worker = worker
        super.init(nibName: nil, bundle: nil)
    }
    
    internal required init?(coder aDecoder: NSCoder)
    {
        self.worker = nil
        super.init(coder: aDecoder)
    }
    
    // MARK: View lifecycle
    
    internal override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.title = "Worker: \(self.worker.identifier)"
        
        // Table view
        self.tableView.backgroundColor = UIColor.whiteColor()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        self.reloadData()
    }
    
    internal override func viewDidLayoutSubviews()
    {
        let bounds = self.view.bounds
        self.tableView.frame = bounds
    }
    
    internal override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: -
    
    private func reloadData()
    {
        self.worker.requestAllJobs { [weak self] (jobs) in
            dispatch_async(dispatch_get_main_queue(), { 
                self?.jobs = jobs
            })
        }
    }
    
    // MARK: UITableViewDataSource
    
    internal func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.jobs.count
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellIdentifier = "cellIdentifier"
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: cellIdentifier)
        }
        
        let job = self.jobs[indexPath.row]
        
        cell.textLabel?.text = job.identifier
        cell.textLabel?.font = UIFont.systemFontOfSize(10.0)
        
        cell.detailTextLabel?.text = "Retry count: \(job.numberOfRetries)"
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(12.0)
        cell.accessoryType = .DisclosureIndicator
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let job = self.jobs[indexPath.row]
        let jobDetailsViewController = KyuJobDetailsViewController(job: job)
        
        self.navigationController?.pushViewController(jobDetailsViewController, animated: true)
    }
}
