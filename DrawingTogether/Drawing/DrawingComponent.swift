//
//  DrawingComponent.swift
//  Parser
//
//  Created by 권나연 on 2020/06/01.
//  Copyright © 2020 Na Yeon Kwon. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit


class DrawingComponent: Codable, DrawingComponentProtocol {
    
    var de: String? //
    
    var points = [Point]()
    var id: Int?
    var username: String?
    var usersComponentId: String?
    var type: ComponentType?
    var strokeColor: String? //
    var fillColor: String?
    var strokeAlpha: Int?
    var fillAlpha: Int?
    var strokeWidth: CGFloat?
    var preSize: Int = 0
    var drawnCanvasWidth: CGFloat?
    var drawnCanvasHeight: CGFloat?
    var xRatio: CGFloat = 1.0
    var yRatio: CGFloat = 1.0
    var beginPoint: Point?
    var endPoint: Point?
    var datumPoint: Point?
    var width: Int?
    var height: Int?
    var isErased: Bool = false
    var isSelected: Bool = false
    
    
    //    init() {
    //        self.points = []
    //        self.preSize = 0
    //        self.xRatio = 1.0
    //        self.yRatio = 1.0
    //        self.isErased = false
    //    }
    
    func addPoint(_ point: Point) {
        self.points.append(point)
    }
    
    func clearPoints() {
        self.points = []
        self.preSize = 0
    }
    
    func getPointSize() -> Int { return self.points.count }
    
    func calculateRatio(myCanvasWidth: CGFloat, myCanvasHeight: CGFloat) {
        self.xRatio = myCanvasWidth / drawnCanvasWidth!
        self.yRatio = myCanvasHeight / drawnCanvasHeight!
    }
    
    func draw(drawingView: DrawingView) {
        
    }
    
    func drawComponent(drawingView: DrawingView) {
        
    }
    
    /*func getUIColorFromAndroidColorInt(intColor: Int) -> UIColor {
        let red = (CGFloat) ( (intColor>>16)&0xFF )
        let green = (CGFloat) ( (intColor>>8)&0xFF )
        let blue = (CGFloat) ( (intColor)&0xFF )
        
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }*/
    
    func hexStringToUIColor(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
