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
    
    @IBOutlet weak var rect: UIStackView!
    @IBOutlet weak var oval: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let rectTabGesture = UITapGestureRecognizer(target: self, action: #selector(clickRect))
        rect.addGestureRecognizer(rectTabGesture)
        
        let ovalTabGesture = UITapGestureRecognizer(target: self, action: #selector(clickOval))
        oval.addGestureRecognizer(ovalTabGesture)
    }
    
    @objc func clickRect() {
        de.currentMode = Mode.DRAW
        de.currentType = ComponentType.RECT
        dismiss(animated: true, completion: nil)
    }
    
    @objc func clickOval() {
        de.currentMode = Mode.DRAW
        de.currentType = ComponentType.OVAL
        dismiss(animated: true, completion: nil)
    }

}
