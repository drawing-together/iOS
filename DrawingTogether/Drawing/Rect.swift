//
//  Rect.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/08.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import CoreGraphics

class Rect: DrawingComponent {
    
    override func draw(drawingView: DrawingView) {
        drawingView.redraw(usersComponentId: self.usersComponentId!)
        drawComponent(drawingView: drawingView)
    }
    
    override func drawComponent(drawingView: DrawingView) {
        UIGraphicsBeginImageContext(drawingView.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawingView.image?.draw(in: drawingView.bounds)
        
        //      context.setBlendMode(.normal)
        //      context.setBlendMode(.clear)
        
        let from = self.beginPoint
        let to = self.endPoint
        //let width = (to!.x - from!.x) == 0 ? 1 : abs(to!.x - from!.x)
        //let height = (to!.y - from!.y) == 0 ? 1 : abs(to!.y - from!.y)
        let width = abs(to!.x - from!.x)
        let height = abs(to!.y - from!.y)
        
        var datum:Point = (from!.x < to!.x) ? from! : to! //기준점 (사각형의 왼쪽위 꼭짓점)
        let slope:Float = Float(to!.x - from!.x) == 0 ? 0 : Float(to!.y - from!.y) / Float(to!.x - from!.x)
        
        if slope == 0 {
            if (to!.x - from!.x) == 0 {
                datum = (from!.y < to!.y) ? from! : to!
            }
        } else if slope < 0 {
            datum = Point(x: datum.x, y: datum.y - height)
        }
        
        let rect = CGRect(x: CGFloat(datum.x) * xRatio, y: CGFloat(datum.y) * yRatio, width: CGFloat(width) * xRatio, height: CGFloat(height) * yRatio)
        
        print("shape drawComponent begin=\(String(describing: from?.toString())), end=\(String(describing: to?.toString())), slope=\(slope), xRatio=\(xRatio), yRatio=\(yRatio)")
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(self.strokeWidth! / 2)     // **
        
        context.setFillColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
        context.setAlpha(0.3)
        context.fill(rect)
        
        context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)   // **
        context.setAlpha(1.0)
        context.stroke(rect)
        
        context.strokePath()
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
}
