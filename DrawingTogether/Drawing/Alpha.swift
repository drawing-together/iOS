//
//  Alpha.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/07/23.
//  Copyright © 2020 hansung. All rights reserved.
//

import CoreML

class Alpha {
    
    static func getIOSAlpha(alpha: Int) -> CGFloat {
        return CGFloat(alpha) / 255
    }
    
    static func getAndroidAlpha(alpha: CGFloat) -> Int {
        return Int(255.0 * alpha)
    }
}
