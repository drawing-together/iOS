//
//  DrawingComponentProtocol.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/13.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import CoreGraphics

protocol DrawingComponentProtocol {
    
    /*var de: String { get set } // JSON 형식에 이 변수가 왜 들어가있는지? ( 'RECT' Parsing )
    
    var points: [CGPoint] { get set }
    var id: Int { get set }
    var username: String { get set }
    var userComponentId: String { get set }
    var type: ComponentType { get set }
    var strokeColor: Int { get set }
    var fillColor: Int { get set }
    var strokeAlpha: Int { get set }
    var fillAlpha: Int { get set }
    var strokeWidth: Int { get set }
    var preSize: Int { get set }
    var drawnCanvasWidth: Float { get set }
    var drawnCanvasHeight: Float { get set }
    var xRatio: Float { get set }
    var yRatio: Float { get set }
    var beginPoint: Point { get set }
    var endPoint: Point { get set }
    var datumPoint: Point { get set }
    var width: Int { get set }
    var height: Int { get set }
    var isErased: Bool { get set }
    var isSelected: Bool { get set }
    
    
    func addPoint(_ point: Point) -> Void
    
    func clearPoints() -> Void
    
    func getPointSize() -> Int
    
    func calcRatio(myCanvasWidth: Float, myCanvasHeight: Float) -> Void
     */
    
    func draw(drawingView: DrawingView) -> Void
    
    func drawComponent(drawingView: DrawingView) -> Void
    //func toString() -> String
}

