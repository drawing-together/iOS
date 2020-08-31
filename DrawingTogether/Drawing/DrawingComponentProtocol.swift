//
//  DrawingComponentProtocol.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/13.
//  Copyright © 2020 hansung. All rights reserved.
//

protocol DrawingComponentProtocol {
    
    func draw(view: UIImageView, drawingEditor: DrawingEditor) -> Void
    
    func drawComponent(view: UIImageView, drawingEditor: DrawingEditor) -> Void
    
    //func toString() -> String
}

