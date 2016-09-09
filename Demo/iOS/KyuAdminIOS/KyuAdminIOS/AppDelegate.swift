//
//  AppDelegate.swift
//  KyuAdminIOS
//
//  Created by Red Davis on 21/06/2016.
//  Copyright © 2016 Red Davis. All rights reserved.
//

import UIKit
import Kyu_iOS


class TestJob: KyuJobProtocol
{
    func perform(arguments: [String : AnyObject]) -> KyuJobResult
    {
        sleep(1)
        return KyuJobResult.success
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    // Private
    private var kyu: Kyu!
    
    private var rootNavigationController: UINavigationController!
    private var kyuWorkersViewController: KyuWorkersListViewController!
    
    private var addJobsTimer: NSTimer?
    
    // MARK: UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        self.kyu = try! Kyu.configure { (config: KyuConfiguration) -> () in
            config.numberOfWorkers = 1
            config.directoryURL = NSURL(string: NSTemporaryDirectory() + "\(arc4random())\(arc4random())")!
            config.job = TestJob()
        }
        
        self.kyuWorkersViewController = KyuWorkersListViewController(kyu: self.kyu)
        self.rootNavigationController = UINavigationController(rootViewController: self.kyuWorkersViewController)
        
        // Window
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = self.rootNavigationController
        self.window?.backgroundColor = UIColor.whiteColor()
        self.window?.makeKeyAndVisible()
        
        // Add jobs
        for _ in 0...100
        {
            self.kyu.queueJob(["1":"2"])
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication)
    {
        
    }

    func applicationDidEnterBackground(application: UIApplication)
    {
        
    }

    func applicationWillEnterForeground(application: UIApplication)
    {

    }

    func applicationDidBecomeActive(application: UIApplication)
    {

    }

    func applicationWillTerminate(application: UIApplication)
    {

    }
}
