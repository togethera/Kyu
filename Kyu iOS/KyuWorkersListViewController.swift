//
//  KyuWorkersListViewController.swift
//  Kyu
//
//  Created by Red Davis on 21/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import UIKit


public class KyuWorkersListViewController: UIViewController, UITableViewDataSource,
                                           UITableViewDelegate
{
    // Private
    private let kyu: Kyu!
    private var kyuViewModel: KyuViewModel!
    
    private var pollingTimer: NSTimer?
    
    private let tableView = UITableView(frame: CGRect.zero, style: .Plain)
    private let startPollingButton = UIBarButtonItem(title: "Start Polling", style: .Plain, target: nil, action: nil)
    private let pausePollingButton = UIBarButtonItem(title: "Pause Polling", style: .Plain, target: nil, action: nil)
    
    // MARK: Initialization
    
    public required init(kyu: Kyu)
    {
        self.kyu = kyu
        self.kyuViewModel = KyuViewModel(kyu: kyu)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        self.kyu = nil
        self.kyuViewModel = nil
        super.init(coder: aDecoder)
    }
    
    // MARK: View lifecycle
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.title = "Kyu Workers"
        
        // Table view
        self.tableView.backgroundColor = UIColor.whiteColor()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        // Bar items
        self.startPollingButton.target = self
        self.startPollingButton.action = #selector(KyuWorkersListViewController.startPollingButtonTapped(_:))
        
        self.pausePollingButton.target = self
        self.pausePollingButton.action = #selector(KyuWorkersListViewController.pausePollingButtonTapped(_:))
        
        self.navigationItem.rightBarButtonItem = self.pausePollingButton
        self.startPollingTimer()
    }
    
    public override func viewDidLayoutSubviews()
    {
        let bounds = self.view.bounds
        self.tableView.frame = bounds
    }

    public override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Data reload
    
    private func reloadData()
    {
        self.kyuViewModel = KyuViewModel(kyu: self.kyu)
        self.tableView.reloadData()
    }
    
    private func startPollingTimer()
    {
        self.pollingTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(KyuWorkersListViewController.pollingTimerFired(_:)), userInfo: nil, repeats: true)
    }
    
    private func invalidatePollingTimer()
    {
        self.pollingTimer?.invalidate()
        self.pollingTimer = nil
    }
    
    // MARK: Actions
    
    internal func startPollingButtonTapped(sender: AnyObject)
    {
        self.startPollingTimer()
        self.navigationItem.rightBarButtonItem = self.pausePollingButton
    }
    
    internal func pausePollingButtonTapped(sender: AnyObject)
    {
        self.invalidatePollingTimer()
        self.navigationItem.rightBarButtonItem = self.startPollingButton
    }
    
    // MARK: Timers
    
    internal func pollingTimerFired(timer: NSTimer)
    {
        self.reloadData()
    }
    
    // MARK: UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.kyuViewModel.workers.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cellIdentifier = "cellIdentifier"
        var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: cellIdentifier)
        }
        
        let worker = self.kyuViewModel.workers[indexPath.row]
        cell.textLabel?.text = worker.identifier
        cell.detailTextLabel?.text = "Jobs: \(worker.numberOfJobs)"
        cell.accessoryType = .DisclosureIndicator
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let worker = self.kyuViewModel.workers[indexPath.row]
        let jobsListViewController = KyuJobsListViewController(worker: worker)
        self.navigationController?.pushViewController(jobsListViewController, animated: true)
    }
}
