//
//  JoinMessage.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/08.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class JoinMessage: Codable {
    
    var name: String?
    
    init(name: String) {
        self.name = name
    }
}
