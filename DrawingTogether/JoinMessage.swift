//
//  JoinMessage.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/08.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class JoinMessage: Codable {
    var master: String?
    var name: String?
    
    var to: String?
    var userList: [User]?
    
    init(master: String, to: String, userList: [User]) {
        self.master = master
        self.to = to
        self.userList = userList
    }
    
    init(name: String) {
        self.name = name
    }
}
