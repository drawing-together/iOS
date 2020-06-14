//
//  DeleteMessage.swift
//  DrawingTogether
//
//  Created by admin on 2020/06/08.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class DeleteMessage: Codable {
    var name: String?
    
    init(name: String) {
        self.name = name
    }
}
