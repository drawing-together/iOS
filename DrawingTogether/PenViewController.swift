//
//  PenViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/09/02.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class PenViewController: UIViewController {
    
    let de = DrawingEditor.INSTANCE
    
    @IBOutlet weak var pen1: UIStackView!
    @IBOutlet weak var pen2: UIStackView!
    @IBOutlet weak var pen3: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let pen1TabGesture = UITapGestureRecognizer(target: self, action: #selector(clickPen1))
        pen1.addGestureRecognizer(pen1TabGesture)
        
        let pen2TabGesture = UITapGestureRecognizer(target: self, action: #selector(clickPen2))
        pen2.addGestureRecognizer(pen2TabGesture)
        
        let pen3TabGesture = UITapGestureRecognizer(target: self, action: #selector(clickPen3))
        pen3.addGestureRecognizer(pen3TabGesture)
    }
    
    @objc func clickPen1() {
        de.strokeWidth = 10
        dismiss(animated: true, completion: nil)
    }
    
    @objc func clickPen2() {
        de.strokeWidth = 20
        dismiss(animated: true, completion: nil)
    }
    
    @objc func clickPen3() {
        de.strokeWidth = 30
        dismiss(animated: true, completion: nil)
    }
}
