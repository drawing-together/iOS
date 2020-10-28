//
//  EraserViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/08/28.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class EraserViewController: UIViewController {

    let de = DrawingEditor.INSTANCE
    let client = MQTTClient.client
    
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var backgroundClearBtn: UIButton!
    @IBOutlet weak var drawingViewClearBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if (!client.master) {
            clearBtn.isEnabled = false
            clearBtn.setTitleColor(UIColor.gray, for: .normal)
            backgroundClearBtn.isEnabled = false
            backgroundClearBtn.setTitleColor(UIColor.gray, for: .normal)
            drawingViewClearBtn.isEnabled = false
            drawingViewClearBtn.setTitleColor(UIColor.gray, for: .normal)
        }
    }
    
    @IBAction func clickClearBtn(_ sender: UIButton) {
        de.drawingView!.clear()
    }
    
    @IBAction func clickBackgroundClearBtn(_ sender: UIButton) {
        de.drawingView!.clearBackgroundImage()
    }
    
    @IBAction func clickDrawingViewClearBtn(_ sender: UIButton) {
        de.drawingView!.clearDrawingView()
    }
    
    
}
