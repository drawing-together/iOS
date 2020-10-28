//
//  EraseCommand.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class EraseCommand: Command {
    var eraser: Eraser?
    var ids: [Int]?
    
    init() {
        eraser = Eraser()
        ids = eraser!.erasedComponentIds
    }
    
    func execute(point: Point) {
        eraser!.findComponentsToErase(eraserPoint: point)
        
    }

    func getIds() -> [Int] {
        return ids!
    }
}
