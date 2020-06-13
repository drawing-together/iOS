//
//  DrawingView.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class DrawingView: UIView {
    
    var stroke: Stroke?

    override func draw(_ rect: CGRect) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        setNeedsDisplay()
    }
    
}
