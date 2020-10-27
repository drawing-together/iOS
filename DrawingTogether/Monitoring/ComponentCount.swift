//
//  ComponentCount.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/10/27.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class ComponentCount: Codable {
    
    var topic: String!
    var stroke: Int!
    var rect: Int!
    var oval: Int!
    var text: Int!
    var image: Int!
    var erase: Int!
    
    init(topic: String) {
        self.topic = topic
        stroke = 0
        rect = 0
        oval = 0
        text = 0
        image = 0
        erase = 0
    }
    
    func increaseStroke() { stroke+=1; }

    func increaseRect() { rect+=1; }

    func increaseOval() { oval+=1; }

    func increaseText() { text+=1; }

    func increaseImage() { image+=1; }
    
    func increaseErase() { erase+=1; }
    
}
