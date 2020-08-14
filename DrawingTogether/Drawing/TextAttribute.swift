//
//  TextAttribute.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/09.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import UIKit

class TextAttribute: Codable {
    
    var id: String?
    var username: String?
    
    var preText: String?
    var postText: String?
    var text: String?
    var textSize: Int?
    var textColor: String? // hex string
    var textBackgroundColor: Int?
    var textGravity: Int?
    var style: Int?
    
    var generatedLayoutWidth: Int?
    var generatedLayoutHeight: Int?
    
    var preX: Int?
    var preY: Int?
    var postX: Int?
    var postY: Int?
    var x: Int?
    var y: Int?
    
    var isModified: Bool = false
    var isTextInited: Bool = false
    var isTextMoved: Bool = false
    var isTextChangedColor: Bool = false
    
    
    init(textAttr: TextAttribute) {
        self.id = textAttr.id
        self.username = textAttr.username
        
        self.preText = textAttr.preText
        self.postText = textAttr.postText
        self.text = textAttr.text
        self.textSize = textAttr.textSize
        self.textColor = textAttr.textColor
        self.textBackgroundColor = textAttr.textBackgroundColor
        self.textGravity = textAttr.textGravity
        self.style = textAttr.style
        self.generatedLayoutWidth = textAttr.generatedLayoutWidth
        self.generatedLayoutHeight = textAttr.generatedLayoutHeight
        
        self.preX = textAttr.preX
        self.preY = textAttr.preY
        self.postX = textAttr.postX
        self.postY = textAttr.postY
        self.x = textAttr.x
        self.y = textAttr.y
    }
    
    
    init(id: String, username: String, text:String, textSize: Int, textColor: String, textBackgroundColor: Int?, textGravity: Int?, style: Int?, generatedLayoutWidth: Int?, generatedLayoutHeight: Int?) {
        self.id = id
        self.username = username
        
        self.text = text
        self.textSize = textSize
        self.textColor = textColor
        self.textBackgroundColor = textBackgroundColor
        self.textGravity = textGravity
        self.style = style
        self.generatedLayoutWidth = generatedLayoutWidth
        self.generatedLayoutHeight = generatedLayoutHeight
    }
    
    
    func setCoordinate(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    func setPreCoordinate(preX: Int, preY: Int) {
        self.preX = preX
        self.preY = preY
    }

    
    func hexStringToUIColor() -> UIColor {
        var cString:String = self.textColor!.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
}
