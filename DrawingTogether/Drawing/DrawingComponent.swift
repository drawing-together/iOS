//
//  DrawingComponent.swift
//  Parser
//
//  Created by 권나연 on 2020/06/01.
//  Copyright © 2020 Na Yeon Kwon. All rights reserved.
//

import Foundation
import CoreGraphics



class DrawingComponent: Codable{
    
    var de: String? // JSON 형식에 이 변수가 왜 들어가있는지? ( 'RECT' Parsing )
    
    var points: [Point] = []
    var id: Int?
    var username: String?
    var userComponentId: String?
    var type: ComponentType?
    var strokeColor: Int? //
    var fillColor: Int?
    var strokeAlpha: Int?
    var fillAlpha: Int?
    var strokeWidth: Int?
    var preSize: Int = 0
    var drawnCanvasWidth: Float?
    var drawnCanvasHeight: Float?
    var xRatio: Float = 1.0
    var yRatio: Float = 1.0
    var beginPoint: Point?
    var endPoint: Point?
    var datumPoint: Point?
    var width: Int?
    var height: Int?
    var isErased: Bool = false
    
    
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
    
    func calcRatio(myCanvasWidth: Float, myCanvasHeight: Float) {
            self.xRatio = myCanvasWidth / drawnCanvasWidth!
            self.yRatio = myCanvasHeight / drawnCanvasHeight!
    }

}

protocol DrawingComponentProtocol {
    func draw() -> Void
    func drawComponent() -> Void
    //func toString() -> String
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
