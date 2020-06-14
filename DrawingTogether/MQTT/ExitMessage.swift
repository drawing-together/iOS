//
//  ExitMessage.swift
//  DrawingTogether
//
//  Created by admin on 2020/06/08.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class ExitMessage: Codable {
    var name: String?
    var message: String?
    
    init(name: String, message: String) {
        self.name = name
        self.message = message
    }
    
    init(name: String) {
        self.name = name
    }
}
