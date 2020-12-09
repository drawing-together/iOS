//
//  DrawingItem.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class DrawingItem: Codable {
    var mode: Mode?
//    var components = [DrawingComponentAdapter]()
    var components: [DrawingComponentAdapter]?
    var textMode: TextMode?
    var textAttribute: TextAttribute?
    var component: DrawingComponentAdapter?
    var movePoint: Point?
    
    init(mode: Mode, component: DrawingComponentAdapter) {
        self.mode = mode
//        self.components.append(component)
        self.components = [DrawingComponentAdapter]()
        self.components!.append(component)
    }

    init(mode: Mode, components: [DrawingComponentAdapter]) {
        self.mode = mode
//        self.components.append(contentsOf: components)
        self.components = [DrawingComponentAdapter]()
        self.components?.append(contentsOf: components)
    }
    
    init(mode: Mode, component: DrawingComponentAdapter, movePoint: Point) {
        self.mode = mode
        self.component = component
        self.movePoint = movePoint
    }

//    init(textMode: TextMode, textAttribute: TextAttribute) {
//        self.textMode = textMode;
//        self.textAttribute = TextAttribute(textAttr: textAttribute)
//        print("preText=\(textAttribute.preText!), text=\(textAttribute.text!)")
//    }
    
    func getComponents() -> [DrawingComponent] {
        var dcs: [DrawingComponent] = []

        for comp in components! {
            comp.getComponent()!.isSelected = false
            dcs.append(comp.getComponent()!)
        }
        return dcs
    }

    func getComponent() -> DrawingComponent {
        let dc = component!.getComponent()!
        dc.isSelected = false
        return dc
    }
}
