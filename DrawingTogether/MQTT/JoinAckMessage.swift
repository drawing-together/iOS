//
//  JoinAckMessage.swift
//  DrawingTogether
//
//  Created by admin on 2020/08/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class JoinAckMessage: Codable {
    
    var name: String?
    var target: String?
    
    init(name: String, target: String) {
        self.name = name
        self.target = target
    }
}
