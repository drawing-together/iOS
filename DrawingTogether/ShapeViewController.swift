//
//  ShapeViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/08/28.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class ShapeViewController: UIViewController {
    
    let de = DrawingEditor.INSTANCE

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func clickRectBtn(_ sender: UIButton) {
        de.currentMode = Mode.DRAW
        de.currentType = ComponentType.RECT
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func clickOvalBtn(_ sender: UIButton) {
        de.currentMode = Mode.DRAW
        de.currentType = ComponentType.OVAL
        dismiss(animated: true, completion: nil)
    }

}
