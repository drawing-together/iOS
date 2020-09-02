//
//  WarpingMessage.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/07/15.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class WarpingMessage: Codable {
    var action: Int
    var pointerCount: Int
    var x, y: [Int]
    var width, height: Int
    
    init(action: Int, pointerCount: Int, x: [Int], y: [Int], width: Int, height: Int) {
        self.action = action
        self.pointerCount = pointerCount
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    func getWarpData() -> WarpData {
        return WarpData(action: action, x: x, y: y)
    }
}
