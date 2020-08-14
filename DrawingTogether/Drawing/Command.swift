//
//  Command.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

protocol Command {
    func execute(point: Point) -> Void
    func getIds() -> [Int]
}
