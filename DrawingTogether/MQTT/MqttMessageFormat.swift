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
    var movePoints: [Point]?

    var username: String?
    var componentIds: [Int]?
    var isSelected: Bool?
    var moveSelectPoints: [Point]?

    var bitmapByteArray: [Int8]?
    
    var textAttr: TextAttribute?
    var textMode: TextMode?

    var myTextArrayIndex: Int?

    var joinMessage: JoinMessage?
    var joinAckMessage: JoinAckMessage?
    var exitMessage: ExitMessage?
    var closeMessage: CloseMessage?
    var aliveMessage: AliveMessage?
//
//    var audioMessage: AudioMessage?
    var warpingMessage: WarpingMessage?
    
    var autoDrawMessage: AutoDrawMessage?
//
    var drawingComponents: [DrawingComponentAdapter]?
    var texts: [TextAdapter]?
    var history: [DrawingItem]?
    var undoArray: [DrawingItem]?
    var removedComponentId: [Int]?
    var maxComponentId: Int?
    var maxTextId: Int?


    // MARK: DRAWING MESSAGE
    // DRAW - action down
    init(username: String, usersComponentId: String, mode: Mode, type: ComponentType, component:DrawingComponentAdapter, action: Int) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.type = type
        self.component = component
        self.action = action
    }
    
    // DRAW - action up
    init(username: String, usersComponentId: String, mode: Mode, type: ComponentType, point: Point, action: Int) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.type = type
        self.point = point
        self.action = action
    }
    
    // DRAW - move chunk
    init(username: String, usersComponentId: String, mode: Mode, type: ComponentType, movePoints: [Point], action: Int) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.type = type
        self.movePoints = movePoints
        self.action = action
    }
    
    // ERASE
    init(username: String, mode: Mode, componentIds: [Int]) {
        self.username = username
        self.mode = mode
        self.componentIds = componentIds
    }
    
    // MODE CHANGE
    init(username: String, mode: Mode) {
        self.username = username
        self.mode = mode
    }
    
    // SELECT - select, deselect
    init(username: String, usersComponentId: String, mode: Mode, isSelected: Bool) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.isSelected = isSelected
    }
    
    // SELECT - down, move, up
    init(username: String, usersComponentId: String, mode: Mode, action: Int, moveSelectPoints: [Point]) {
        self.username = username
        self.usersComponentId = usersComponentId
        self.mode = mode
        self.action = action
        self.moveSelectPoints = moveSelectPoints
    }
    
 
    // MARK: IMAGE MESSAGE
    init(username: String, mode: Mode, bitmapByteArray: [Int8]) {
        self.username = username
        self.mode = mode
        self.bitmapByteArray = bitmapByteArray
    }

 

    // MARK: TEXT MESSAGE
    init(username: String, mode: Mode, type: ComponentType, textAttr: TextAttribute, textMode: TextMode, myTextArrayIndex: Int) {
        self.username = username
        self.mode = mode
        self.textAttr = textAttr
        self.textMode = textMode
        self.myTextArrayIndex = myTextArrayIndex
    }

    // MARK: MID MESSAGE
    init(joinAckMessage: JoinAckMessage, drawingComponents: [DrawingComponentAdapter], texts: [TextAdapter], history: [DrawingItem], undoArray: [DrawingItem], removedComponentId: [Int], maxComponentId: Int, maxTextId: Int) {
        self.joinAckMessage = joinAckMessage
        self.drawingComponents = drawingComponents
        self.texts = texts
        self.history = history
        self.undoArray = undoArray
        self.removedComponentId = removedComponentId
        self.maxComponentId = maxComponentId
        self.maxTextId = maxTextId
    }
    
    init(joinAckMessage: JoinAckMessage, drawingComponents: [DrawingComponentAdapter], texts: [TextAdapter], history: [DrawingItem], undoArray: [DrawingItem], removedComponentId: [Int], maxComponentId: Int, maxTextId: Int, bitmapByteArray: [Int8]) {
        self.joinAckMessage = joinAckMessage
        self.drawingComponents = drawingComponents
        self.texts = texts
        self.history = history
        self.undoArray = undoArray
        self.removedComponentId = removedComponentId
        self.maxComponentId = maxComponentId
        self.maxTextId = maxTextId
        self.bitmapByteArray = bitmapByteArray
    }
    
    // MARK: WARP MESSAGE
       init(username: String, mode: Mode, type: ComponentType, action: Int, warpingMessage: WarpingMessage) {
           self.username = username
           self.mode = mode
           self.action = action
           self.type = type
           self.warpingMessage = warpingMessage
       }
    
    init(username: String, mode: Mode, type: ComponentType, autoDrawMessage: AutoDrawMessage) {
        self.username = username
        self.mode = mode
        self.type = type
        self.autoDrawMessage = autoDrawMessage
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
    
    init(joinAckMessage: JoinAckMessage) {
        self.joinAckMessage = joinAckMessage
    }

    init(exitMessage: ExitMessage) {
        self.exitMessage = exitMessage
    }
    
    init(closeMessage: CloseMessage) {
        self.closeMessage = closeMessage
    }
    
    init(aliveMessage: AliveMessage) {
        self.aliveMessage = aliveMessage
    }
    
}
