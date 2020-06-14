//
//  TextMode.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

enum TextMode: String, Codable {
    case DRAG_STARTED, DRAG_LOCATION, DROP, DRAG_ENDED, DRAG_EXITED
    case MODIFY_START, MODIFY, DONE
    case ERASE
    case START_COLOR_CHANGE, FINISH_COLOR_CHANGE
}
