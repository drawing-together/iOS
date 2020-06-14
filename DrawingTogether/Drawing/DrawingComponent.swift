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
    
    var de: String? // JSON 형식에 이 변수가 왜 들어가있는지? ( 'RECT' Parsing )
    
    var points = [Point]()
    var id: Int?
    var username: String?
    var usersComponentId: String?
    var type: ComponentType?
    var strokeColor: Int? //
    var fillColor: Int?
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
    
    func getUIColorFromAndroidColorInt(intColor: Int) -> UIColor {
        let red = (CGFloat) ( (intColor>>16)&0xFF )
        let green = (CGFloat) ( (intColor>>8)&0xFF )
        let blue = (CGFloat) ( (intColor)&0xFF )
        
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
}












//protocol DrawingComponent {
//
//    var points: [CGPoint] { get set }
//    var id: Int? { get }
//    var username: String? { get }
//    var userComponentId: String? { get }
//    var type: ComponentType? { get }
//    var strokeColor: CGColor? { get }
//    var fillColor: CGColor? { get }
//    var strokeAlpha: Int? { get }
//    var fillAlpha: Int? { get }
//    var strokeWidth: Int? { get }
//    var preSize: Int { get set }
//    var drawnCanvasWidth: Float? { get }
//    var drawnCanvasHeight: Float? { get }
//    var xRatio: Float { get set }
//    var yRatio: Float { get set }
//    var beginPoint: CGPoint? { get }
//    var endPoint: CGPoint? { get }
//    var datumPoint: CGPoint? { get }
//    var width: Int? { get }
//    var height: Int? { get }
//    var isErased: Bool { get }
//
//    func draw() -> Void
//    func drawComponent() -> Void
//
//    // func toString() -> String
//}




//protocol DrawingComponentProtocol {
//    func draw() -> Void
//    func drawComponent() -> Void
//    //func toString() -> String
//}
