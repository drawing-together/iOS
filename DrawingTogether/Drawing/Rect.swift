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
    
    override func draw(view: UIImageView, drawingEditor: DrawingEditor) {
        //view.redraw(usersComponentId: self.usersComponentId!)
        //drawComponent(view: view, drawingEditor: drawingEditor)
        
        if(view == drawingEditor.drawingVC?.myCurrentView) {
            view.image = nil
            drawComponent(view: view, drawingEditor: drawingEditor)
        } else if(view == drawingEditor.drawingVC?.currentView) {
            view.image = nil
            drawingEditor.drawOthersCurrentComponent(username: nil)
        }
    }
    
    override func drawComponent(view: UIImageView, drawingEditor: DrawingEditor) {
        //UIGraphicsBeginImageContext(drawingView.frame.size)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: drawingEditor.myCanvasWidth!, height: drawingEditor.myCanvasHeight!), false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        view.image?.draw(in: view.bounds)
        
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
        
        //print("shape drawComponent points.count=\(self.points.count), begin=\(String(describing: from?.toString())), end=\(String(describing: to?.toString())), slope=\(slope), width=\(CGFloat(width) * xRatio), height=\(CGFloat(height) * yRatio), xRatio=\(xRatio), yRatio=\(yRatio)")
        
        //context.setLineCap(.square)
        //context.setLineJoin(.round)
        context.setLineWidth(self.strokeWidth! / 2)     // **
        
        context.setFillColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
        context.setAlpha(Alpha.getIOSAlpha(alpha: self.fillAlpha!))
        context.fill(rect)
        
        context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)   // **
        context.setAlpha(Alpha.getIOSAlpha(alpha: self.strokeAlpha!))
        context.stroke(rect)
        
        context.strokePath()
        
        view.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    
}
