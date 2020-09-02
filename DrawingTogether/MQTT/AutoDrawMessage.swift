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
    
    init(name: String, url: String, x: Float, y: Float) {
        self.name = name
        self.url = url
        self.x = x
        self.y = y
    }
}
