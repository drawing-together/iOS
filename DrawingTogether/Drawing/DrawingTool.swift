//
//  DrawingTool.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/07/23.
//  Copyright © 2020 hansung. All rights reserved.
//

class DrawingTool {
    var command: Command?
    var ids: [Int]?

    public init() {  }
    
    public init(command: Command) {
        self.command = command
    }

    public func doCommand(selectedPoint: Point) {    //fixme grouping 이면 ArrayList<Point>이므로 수정 필요
        if let c = command {
            c.execute(point: selectedPoint)
        }
    }
    
    public func getIds() -> [Int]? {
        if let c = command {
            return c.getIds()
        }
        return nil
    }
}
