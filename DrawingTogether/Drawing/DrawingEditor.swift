//
//  DrawingEditor.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import UIKit

class DrawingEditor {
    static let INSTANCE = DrawingEditor()
    private init() {  }
    
    
    var drawingComponents: [DrawingComponent] = []
    
    // MARK: 드로잉 컴포넌트 속성
    var currentMode: Mode?
    var currentType: ComponentType?
    var myUsername: String?
    var username: String?
    var drawnCanvasWidth: Float?
    var drawnCanvasHeight: Float?
    var myCanvasWidth: Float?
    var myCanvasHeight: Float?
    
    
    // MARK: 텍스트에 필요한 객체
    var texts: [Text] = []
    var currentText: Text?
    var isTextBeingEditied = false
    
    var isMidEntered = false
    
    // MARK: 텍스트 속성
    var textSize = UIFont.systemFont(ofSize: 20)
    var textColor = UIColor.black
    var textBackgroundColor: UIColor?
    // var fontStyle
    
    
}
