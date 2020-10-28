//
//  AutoDraw.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/10/27.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class AutoDraw : Codable {
    var width: Float
    var height: Float
    var point: Point
    var url: String
    
    init(width: Float, height: Float, point: Point, url: String) {
        self.width = width
        self.height = height
        self.point = point
        self.url = url
    }
}
