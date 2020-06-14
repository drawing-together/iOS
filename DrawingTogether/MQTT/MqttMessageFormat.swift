//
//  MqttMessageFormat.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import CoreGraphics

class MqttMessageFormat: Codable {
    
    var mode: Mode?
    var type: ComponentType?
    var component: DrawingComponentAdapter? // MARK: "DrawingComponentAdapter" Type
    var componentAdapter: DrawingComponentAdapter?
    var action: Int?
    var usersComponentId: String?
    var point: Point?

    var username: String?
    var componentIds: [Int]?

    var bitmapByteArray: [UInt8]?
    
//    var textAttr: TextAttribute?
//    var textMode: TextMode?
//
//    var myTextArrayIndex: Int?
//
    var joinMessage: JoinMessage?
    var notiMessage: NotiMessage?
    var exitMessage: ExitMessage?
    var deleteMessage: DeleteMessage?
//    var AliveMessage: aliveMessage?
//
//    var audioMessage: AudioMessage?
//    var warpingMessage: WarpingMessage?
//
    var drawingComponents: [DrawingComponentAdapter]?
    var texts: [TextAttribute]?
    var history: [DrawingItem]?
    var undoArray: [DrawingItem]?
    var removedComponentId: [Int]?
    var maxComponentId: Int?
    var maxTextId: Int?


    // MARK: DRAWING MESSAGE
    init(username: String, usersComponentId: String, mode: Mode, type: ComponentType, component:DrawingComponentAdapter, action: Int) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.type = type
        self.component = component
        self.action = action
    }
    
    init(username: String, usersComponentId: String, mode: Mode, type: ComponentType, point: Point, action: Int) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.type = type
        self.point = point
        self.action = action
    }
    
    init(username: String, mode: Mode) {
        self.username = username
        self.mode = mode
    }
 
    // MARK: IMAGE MESSAGE
    init(username: String, mode: Mode, bitmapByteArray: [UInt8]) {
        self.username = username
        self.mode = mode
        self.bitmapByteArray = bitmapByteArray
    }

 
/*
    // MARK: TEXT MESSAGE
    init(username: String, mode: Mode, type: ComponentType, textAttr: TextAttribute, textMode: TextMode, myTextArrayIndex: Int) {
        self.username = username
        self.mode = mode
        self.textAttr = textAttr
        self.textMode = textMode
        self.myTextArrayIndex = myTextArrayIndex
    }
*/
    // MARK: MID MESSAGE
    init(joinMessage: JoinMessage, drawingComponents: [DrawingComponentAdapter], texts: [TextAttribute], history: [DrawingItem], undoArray: [DrawingItem], removedComponentId: [Int], maxComponentId: Int, maxTextId: Int) {
        self.joinMessage = joinMessage
        self.drawingComponents = drawingComponents
        self.texts = texts
        self.history = history
        self.undoArray = undoArray
        self.removedComponentId = removedComponentId
        self.maxComponentId = maxComponentId
        self.maxTextId = maxTextId
    }
    
    init(joinMessage: JoinMessage, drawingComponents: [DrawingComponentAdapter], texts: [TextAttribute], history: [DrawingItem], undoArray: [DrawingItem], removedComponentId: [Int], maxComponentId: Int, maxTextId: Int, bitmapByteArray: [UInt8]) {
        self.joinMessage = joinMessage
        self.drawingComponents = drawingComponents
        self.texts = texts
        self.history = history
        self.undoArray = undoArray
        self.removedComponentId = removedComponentId
        self.maxComponentId = maxComponentId
        self.maxTextId = maxTextId
        self.bitmapByteArray = bitmapByteArray
    }

    
/*
    // MARK: AUDIO MESSAGE
    init(audioMessage: AudioMessage) {
        self.audioMessage = audioMessage
    }
    
    // MARK: WARPING MESSAGE
    init(username: String, mode: Mode, type: ComponentType, action: Int, warpingMessage: WarpingMessage) {
        self.username = username
        self.mode = mode
        self.type = type
        self.action = action
        self.warpingMessage = warpingMessage
    }
*/
    
    // MARK: JOIN MESSAGE
    init(joinMessage: JoinMessage) {
        self.joinMessage = joinMessage
    }
    
    init(notiMessage: NotiMessage) {
        self.notiMessage = notiMessage
    }

    init(exitMessage: ExitMessage) {
        self.exitMessage = exitMessage
    }
    
    init(deleteMessage: DeleteMessage) {
        self.deleteMessage = deleteMessage
    }
/*
    init(aliveMessage: AliveMessage) {
        self.aliveMessage = aliveMessage
    }
    
    init(notiMessage: NotiMessage) {
        self.notiMessage = notiMessage
    }
 */
    
}
