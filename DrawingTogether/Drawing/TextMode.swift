//
//  TextMode.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

enum TextMode: String, Codable {
    case CREATE
    
    case DRAG_STARTED
    case DRAG_LOCATION
    case DROP
    case DRAG_ENDED
    case DRAG_EXITED
    
    case MODIFY_START
    case DONE
    
    case ERASE
    
    case START_COLOR_CHANGE
    case FINISH_COLOR_CHANGE
}
