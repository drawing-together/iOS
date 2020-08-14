//
//  Stroke.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import CoreGraphics

class Stroke: DrawingComponent {
    
    override func draw(drawingView: DrawingView) {
        UIGraphicsBeginImageContext(drawingView.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawingView.image?.draw(in: drawingView.bounds)
        
        //      context.setBlendMode(.normal)
        //      context.setBlendMode(.clear)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(self.strokeWidth! / 2)     // TODO: width
        context.setAlpha(Alpha.getIOSAlpha(alpha: self.strokeAlpha!))
        //context.setStrokeColor(self.getUIColorFromAndroidColorInt(intColor: self.strokeColor!).cgColor)   // TODO: color
        context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
        
        let from = (self.preSize == 0) ? self.points[preSize] : self.points[preSize - 1]
        let to = self.points[preSize]
        
        context.move(to: CGPoint(x: CGFloat(from.x) * (xRatio), y: CGFloat(from.y) * (yRatio)))
        context.addLine(to: CGPoint(x: CGFloat(to.x) * (xRatio), y: CGFloat(to.y) * (yRatio)))
        //print("\(CGFloat(to.x) * (xRatio)), \(CGFloat(to.y) * (yRatio))")
        //print("draw xRatio=\(xRatio), yRatio=\(yRatio)")
        
        context.strokePath()
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func drawComponent(drawingView: DrawingView) {
        UIGraphicsBeginImageContext(drawingView.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawingView.image?.draw(in: drawingView.bounds)
        
        //      context.setBlendMode(.normal)
        //      context.setBlendMode(.clear)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(self.strokeWidth! / 2)     // **
        context.setAlpha(Alpha.getIOSAlpha(alpha: self.strokeAlpha!))
        //context.setStrokeColor(self.getUIColorFromAndroidColorInt(intColor: self.strokeColor!).cgColor)   // **
        context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
        
        //print("drawComponent xRatio=\(xRatio), yRatio=\(yRatio)")
        
        if self.points.count == 0 { return }
        
        context.move(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
        for i in 1..<self.points.count {
            context.addLine(to: CGPoint(x: CGFloat(self.points[i].x) * (xRatio), y: CGFloat(self.points[i].y) * (yRatio)))
            //print("(\(self.points[i].x), \(self.points[i].y))")
        }
        
        context.strokePath()
        drawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}
