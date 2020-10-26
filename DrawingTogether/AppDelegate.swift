//
//  AppDelegate.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/05/21.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appTopic: String?
    var appPassword: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        sleep(1)
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let items = urlComponents?.queryItems {
                
                for item in items {
                    if item.name == "topic" { appTopic = item.value }
                    else if item.name == "password" { appPassword = item.value }
                }
                
                let splashViewController = window?.rootViewController as! SplashViewController
                if let mainVC = splashViewController.mainVC {  // not nil (in running)
                    print("runnging ......")
                    (mainVC as! MainViewController).setKakaoTopic(topic: appTopic!)
                    (mainVC as! MainViewController).setKakaoPassword(password: appPassword!)
                }
            }
            return true
        }
        return false
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let items = urlComponents?.queryItems {
                for item in items {
                    if item.name == "topic" { appTopic = item.value }
                    else if item.name == "password" { appPassword = item.value }
                }
                
                let splashViewController = window?.rootViewController as! SplashViewController
                if let mainVC = splashViewController.mainVC {  // not nil (in running)
                    print("runnging ......")
                    (mainVC as! MainViewController).setKakaoTopic(topic: appTopic!)
                    (mainVC as! MainViewController).setKakaoPassword(password: appPassword!)
                }
            }
            
            return true
        }
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
    }
    
    
}

