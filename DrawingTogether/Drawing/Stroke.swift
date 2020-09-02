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
    
    override func draw(view: UIImageView, drawingEditor: DrawingEditor) {
        
        if(view == drawingEditor.drawingVC?.myCurrentView) {
            view.image = nil
            drawComponent(view: view, drawingEditor: drawingEditor)
            
        } else if(view == drawingEditor.drawingVC?.currentView) {
            view.image = nil
            drawingEditor.drawOthersCurrentComponent(username: nil)
            
        }
    }
    
    override func drawComponent(view: UIImageView, drawingEditor: DrawingEditor) {
        
        autoreleasepool {
            //UIGraphicsBeginImageContext(drawingView.frame.size)
            UIGraphicsBeginImageContextWithOptions(drawingEditor.frameSize!, false, 0)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            view.image?.draw(in: view.bounds)
            
            //      context.setBlendMode(.normal)
            //      context.setBlendMode(.clear)
            
            if self.points.count == 0 { return }
            
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            if(self.penMode == PenMode.NEON) {
                context.setLineWidth(self.strokeWidth! / 2)
                context.setShadow(offset: CGSize.zero, blur: CGFloat((self.strokeWidth! + 10) / 2), color: self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
                context.setBlendMode(.normal)//.multiply)
                context.setStrokeColor(UIColor.white.cgColor)
                
            } else {
                if self.penMode == PenMode.HIGHLIGHT {
                    context.setLineWidth(self.strokeWidth!)
                    context.setAlpha(Alpha.getIOSAlpha(alpha: drawingEditor.highlightAlpha/*self.strokeAlpha!*/))
                } else if self.penMode == PenMode.NORMAL {
                    context.setLineWidth(self.strokeWidth! / 2)
                    context.setAlpha(Alpha.getIOSAlpha(alpha: drawingEditor.normalAlpha/*self.strokeAlpha!*/))
                }
                context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
            }
            
            //print("drawComponent xRatio=\(xRatio), yRatio=\(yRatio)")
            
            
            var mX, mY, x, y: CGFloat
            
            if self.points.count == 1 {
                context.move(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
                context.addLine(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
            } else {
                mX = CGFloat(self.points[0].x) * xRatio
                mY = CGFloat(self.points[0].y) * yRatio
                context.move(to: CGPoint(x: mX, y: mY))
                
                for i in 0..<self.points.count-1 {
                    x = CGFloat(self.points[i+1].x) * xRatio
                    y = CGFloat(self.points[i+1].y) * yRatio
                    context.addQuadCurve(to: CGPoint(x: (x + mX)/2, y: (y + mY)/2), control: CGPoint(x: mX, y:mY))
                    mX = x
                    mY = y
                }
                context.addLine(to: CGPoint(x: mX, y: mY))
            }
            
            context.strokePath()
            
            view.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
 
        }
        
    }
    
}
