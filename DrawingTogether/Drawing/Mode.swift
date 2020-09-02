//
//  Mode.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

enum Mode: String, Codable {
    case DRAW
    case ERASE
    case MID
    case TEXT
    case SELECT
    case WARP
    case CLEAR
    case CLEAR_BACKGROUND_IMAGE
    case AUTO
}
