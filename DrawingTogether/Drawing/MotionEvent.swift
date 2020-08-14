//
//  MotionEvent.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/14.
//  Copyright © 2020 hansung. All rights reserved.
//

enum MotionEvent: Int, Codable {
    case ACTION_DOWN = 0
    case ACTION_UP
    case ACTION_MOVE
    //case ACTION_CANCEL
    
    static func actionToString(action: Int) -> String {
        switch action {
        case MotionEvent.ACTION_DOWN.rawValue:
            return "ACTION_DOWN"
        case MotionEvent.ACTION_UP.rawValue:
            return "ACTION_UP"
        case MotionEvent.ACTION_MOVE.rawValue:
            return "ACTION_MOVE"
            
        default:
            return "ACTION_CANCEL"
        }
    }
    
    
    /*
     var description : String {
       switch self {
       // Use Internationalization, as appropriate.
       case .ACTION_DOWN:
         return "ACTION_DOWN"
       case .ACTION_UP:
         return "ACTION_UP"
       case .ACTION_MOVE:
         return "ACTION_MOVE"
       }
     }
     */
}
