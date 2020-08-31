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
        //UIGraphicsBeginImageContext(drawingView.frame.size)
        /*UIGraphicsBeginImageContextWithOptions(CGSize(width: drawingView.bounds.size.width, height: drawingView.bounds.size.height), false, 0)
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
        UIGraphicsEndImageContext()*/
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
        guard let context2 = UIGraphicsGetCurrentContext() else { return }
        view.image?.draw(in: view.bounds)
        
        //      context.setBlendMode(.normal)
        //      context.setBlendMode(.clear)
        
        if self.points.count == 0 { return }
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        if(self.penMode == PenMode.NEON) {
            context.setLineWidth(self.strokeWidth! + 4 / 2)
            context.setShadow(offset: CGSize.zero, blur: 15.0, color: self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
            context.setBlendMode(.normal)//.multiply)
            
            context2.setLineCap(.round)
            context2.setLineJoin(.round)
            context2.setLineWidth((self.strokeWidth! - 4) / 2)
            context2.setStrokeColor(UIColor.white.cgColor)
            
            var mX, mY, x, y: CGFloat
            if self.points.count == 1 {
                context.move(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
                context.move(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
                context2.addLine(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
                context2.addLine(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
            } else {
                mX = CGFloat(self.points[0].x) * xRatio
                mY = CGFloat(self.points[0].y) * yRatio
                context.move(to: CGPoint(x: mX, y: mY))
                context2.move(to: CGPoint(x: mX, y: mY))
                
                for i in 0..<self.points.count-1 {
                    x = CGFloat(self.points[i+1].x) * xRatio
                    y = CGFloat(self.points[i+1].y) * yRatio
                    context.addQuadCurve(to: CGPoint(x: (x + mX)/2, y: (y + mY)/2), control: CGPoint(x: mX, y:mY))
                    context2.addQuadCurve(to: CGPoint(x: (x + mX)/2, y: (y + mY)/2), control: CGPoint(x: mX, y:mY))
                    mX = x
                    mY = y
                }
                context.addLine(to: CGPoint(x: mX, y: mY))
                context2.addLine(to: CGPoint(x: mX, y: mY))
                
            }
            context.strokePath()
            context2.strokePath()
            
        } else {
            if self.penMode == PenMode.HIGHLIGHT {
                context.setAlpha(Alpha.getIOSAlpha(alpha: drawingEditor.highlightAlpha/*self.strokeAlpha!*/))
            } else if self.penMode == PenMode.NORMAL {
                context.setAlpha(Alpha.getIOSAlpha(alpha: drawingEditor.normalAlpha/*self.strokeAlpha!*/))
            }
            
            context.setLineWidth(self.strokeWidth! / 2)     // **
            context.setStrokeColor(self.hexStringToUIColor(hex: self.strokeColor!).cgColor)
            
            //print("drawComponent xRatio=\(xRatio), yRatio=\(yRatio)")
            
            /*context.move(to: CGPoint(x: CGFloat(self.points[0].x) * xRatio, y: CGFloat(self.points[0].y) * yRatio))
            for i in 1..<self.points.count {
                context.addLine(to: CGPoint(x: CGFloat(self.points[i].x) * (xRatio), y: CGFloat(self.points[i].y) * (yRatio)))
                //print("(\(self.points[i].x), \(self.points[i].y))")
            }*/
            
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
        }
        view.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
}
