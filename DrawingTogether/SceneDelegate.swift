//
//  SceneDelegate.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/05/21.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var sceneTopic: String?
    var scenePassword: String?
    
    var scene: UIScene?
    var openURLContexts: Set<UIOpenURLContext>?
    
    var startTime: Date?
    var stopTime: Date?
    var formatter: DateFormatter?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        self.scene = scene
        openURLContexts = connectionOptions.urlContexts
//        self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        
        formatter = DateFormatter()
        formatter?.dateFormat = "YYYY-MM-dd HH:mm:ss"
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("scene url context")
        
        if let urlContext = URLContexts.first {
            if KLKTalkLinkCenter.shared().isTalkLinkCallback(urlContext.url) {
                
                let navigationController = window?.rootViewController as! UINavigationController
                let mainViewController = navigationController.viewControllers.first as! MainViewController
                
                let urlComponents = URLComponents(url: urlContext.url, resolvingAgainstBaseURL: false)
                if let items = urlComponents?.queryItems {
                    
                    for item in items {
                        if item.name == "topic" { sceneTopic = item.value }
                        else if item.name == "password" { scenePassword = item.value }
                    }
                    
                    mainViewController.setKakaoTopic(topic: sceneTopic!)
                    mainViewController.setKakaoPassword(password: scenePassword!)
                    
                }
            }

        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        print("sceneDidDisconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("sceneDidBecomeActive")
        
        startTime = formatter!.date(from: formatter!.string(from: Date()))
        
        let navigationController = window?.rootViewController as! UINavigationController
        let mainVC = navigationController.viewControllers.first as! MainViewController
        
        if mainVC.drawingVCPresented && stopTime != nil {  // 현재 Drawing 화면
            let diff = startTime!.timeIntervalSince(stopTime!)
            
            if diff > 60.0 {
                let client = MQTTClient.client
                client.drawingVC.showAlert(title: "시간 경과", message: "1분 이상 접속하지 않아 메인 화면으로 이동합니다.", selectable: false)
            }
            
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("sceneWillResignActive")
        
        stopTime = formatter!.date(from: formatter!.string(from: Date()))

    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("sceneDidEnterBackground")
    }

}

