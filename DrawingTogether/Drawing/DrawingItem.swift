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
    var components = [DrawingComponentAdapter]()
    var textMode: TextMode?
    var textAttribute: TextAttribute?
    
    init(mode: Mode, component: DrawingComponentAdapter) {
        self.mode = mode
        self.components.append(component)
    }

    init(mode: Mode, components: [DrawingComponentAdapter]) {
        self.mode = mode
        self.components.append(contentsOf: components)
    }

    init(textMode: TextMode, textAttribute: TextAttribute) {
        self.textMode = textMode;
        self.textAttribute = TextAttribute(textAttr: textAttribute)
        print("preText=\(textAttribute.preText!), text=\(textAttribute.text!)")
    }
}
