//
//  AliveMessage.swift
//  DrawingTogether
//
//  Created by admin on 2020/07/13.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class AliveMessage: Codable {
    var name: String?
    
    init(name: String) {
        self.name = name
    }
}
