//
//  Point.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/04.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import CoreGraphics

class Point: Codable {
    var x: Int
    var y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    func toString() -> String {
        return "(\(x), \(y))"
    }
}
