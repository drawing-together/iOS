//
//  WarpData.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/07/15.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class WarpData {
    var action: Int = 0
    var points: [Point] = []
    
    init(action: Int, x: [Int], y: [Int]) {
        self.action = action
        for i in 0...x.count - 1 {
            points.append(Point(x: x[i], y: y[i]))
        }
    }
}
