//
//  SplashViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/06/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import Lottie

class SplashViewController: UIViewController {
    @IBOutlet weak var animation: AnimationView!
    
    var mainVC: UIViewController!  // fixme hyeyeon
    
    override func viewDidLoad() {
      super.viewDidLoad()
        animation.animation = Animation.named("intro")
      
      animation.play { (finished) in
        let vcName = self.storyboard?.instantiateViewController(withIdentifier: "main")
      
        vcName?.modalPresentationStyle = .fullScreen
        self.present(vcName!, animated: false)
        
        let naviagtionController = vcName as! UINavigationController  // fixme hyeyeon
        self.mainVC = naviagtionController.topViewController as! MainViewController
      }
    }
}
