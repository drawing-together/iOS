//
//  DrawingComponentAdapter.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/04.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class DrawingComponentAdapter: Codable {
    var CLASSNAME: String?
    var OBJECT: DrawingComponent?
    
    func getComponent() -> DrawingComponent? {
        
        switch CLASSNAME {
        case "Stroke":
            
            let stroke = JSONParser.parser.createDrawingComponent(dc: OBJECT!)
            
            return stroke
            
        case "Rect":
            
            let rect = JSONParser.parser.createDrawingComponent(dc: OBJECT!)
            
            return rect
            
        default:
            print("error get DrawingComponent")
        }

        return nil
        
    }

    
}
