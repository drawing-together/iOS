//
//  Selector.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/16.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class Selector {
    let de = DrawingEditor.INSTANCE
    let client = MQTTClient.client
    let parser = JSONParser.parser
    let squareScope = 20
    var selectedComponentId = -1

    func findSelectedComponent(selectorPoint: Point) {
        selectedComponentId = -1

        let x = selectorPoint.x
        let y = selectorPoint.y

        if y-squareScope<0 || x-squareScope<0 || y+squareScope>Int(de.myCanvasHeight!) || x+squareScope>Int(de.myCanvasWidth!) {
            print("selector exit")
            return
        }

        if de.findEnclosingDrawingComponents(point: selectorPoint).count != 0 && !de.isContainsRemovedComponentIds(ids: de.findEnclosingDrawingComponents(point: selectorPoint)) {
            selectedComponentId = de.findEnclosingDrawingComponents(point: selectorPoint).last!
            print("selected shape ids = \(selectedComponentId)")
        }
    }
}
