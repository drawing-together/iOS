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
    var components: [DrawingComponentAdapter]?
    var textMode: TextMode?
    var textAttribute: TextAttribute?
}
