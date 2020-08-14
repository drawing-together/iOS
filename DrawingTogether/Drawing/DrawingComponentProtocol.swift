//
//  DrawingComponentProtocol.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/13.
//  Copyright © 2020 hansung. All rights reserved.
//

protocol DrawingComponentProtocol {
    
    func draw(drawingView: DrawingView) -> Void
    
    func drawComponent(drawingView: DrawingView) -> Void
    
    //func toString() -> String
}

