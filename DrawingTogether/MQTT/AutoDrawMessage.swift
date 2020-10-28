//
//  AutoDrawMessage.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/09/01.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class AutoDrawMessage: Codable {
    var name: String
    var url: String
    var x, y: Float
    var width, height: Float
    
    init(name: String, url: String, x: Float, y: Float, width: Float, height: Float) {
        self.name = name
        self.url = url
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
