//
//  SelectorCommandd.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/16.
//  Copyright © 2020 hansung. All rights reserved.
//

class SelectCommand: Command {
    var selector: Selector?
    var ids = [Int]()

    init() {
        selector = Selector()
        //ids = selector!.selectedComponentId
    }
    
    func execute(point: Point) {
        selector!.findSelectedComponent(selectorPoint: point)
    }

    func getIds() -> [Int] {
        ids.removeAll()
        ids.append(selector!.selectedComponentId)
        print("ids[] = \(String(describing: ids))")
        return ids
    }
}
