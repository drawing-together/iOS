  
//
//  User.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//
import Foundation

class User: Codable {
    var name: String?
    var count: Int?
    var action: Int?
    var isInitialized: Bool?

    init(name: String, count: Int, action: Int, isInitialized: Bool) {
        self.name = name
        self.count = count
        self.action = action
        self.isInitialized = isInitialized
    }
}
