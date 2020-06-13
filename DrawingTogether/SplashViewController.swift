//
//  SplashViewController.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/06/13.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import Lottie

class SplashViewController: UIViewController {
    @IBOutlet weak var animation: AnimationView!
    
    override func viewDidLoad() {
      super.viewDidLoad()
        animation.animation = Animation
            .named("intro")
      
      animation.play { (finished) in
        let vcName = self.storyboard?.instantiateViewController(withIdentifier: "main")
      
        vcName?.modalPresentationStyle = .fullScreen
        self.present(vcName!, animated: false)
      }
    }
}
