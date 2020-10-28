//
//  Eraser.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/06/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class Eraser {
    let de = DrawingEditor.INSTANCE
    let client = MQTTClient.client
    let parser = JSONParser.parser
    let sendMqttMessage = SendMqttMessage.INSTANCE
    let squareScope = 10
    var erasedComponentIds = [Int]()
    var shapeIds = [Int]()
    var x = 0
    var y = 0
    var eraserTask: EraserTask
    
    init() {
        eraserTask = EraserTask()
    }
    
    func findComponentsToErase(eraserPoint: Point) {
        erasedComponentIds.removeAll()
        shapeIds.removeAll()
        
        x = eraserPoint.x
        y = eraserPoint.y
        
        //print("\(x), \(y)")
        
        let dbArray = de.drawingBoardArray
        
        if(y-squareScope-1<0 || x-squareScope-1<0 || y+squareScope+1>Int(de.myCanvasHeight!) || x+squareScope+1>Int(de.myCanvasWidth!)) {
            print("eraser exit")
            return
        }
        
        //for i in (y-squareScope)..<(y+squareScope) {
        for i in stride(from: (y-squareScope), through: (y+squareScope), by: 1) {
            //for j in (x-squareScope)..<(x+squareScope) {
            autoreleasepool {
            for j in stride(from: (x-squareScope), through: (x+squareScope), by: 1) {
                autoreleasepool {
                shapeIds = de.findEnclosingDrawingComponents(point: eraserPoint)
                
                if shapeIds.count != 0 && !de.isContainsRemovedComponentIds(ids: shapeIds) {
                    erasedComponentIds.append(contentsOf: shapeIds)
                    //erase(erasedComponentIds: shapeIds)
                    de.addRemovedComponentIds(ids: shapeIds)
                    print("erased shape ids = \(erasedComponentIds)")
                    //erase(erasedComponentIds)
                }
                
                /*var str = "(\(x),\(y)), dbArray[\(i)][\(j)] = "
                 for component in dbArray![i][j] {
                 str += "\(component) "
                 }
                 print(str)*/
                
                
                if(dbArray![i][j].count != 0 && !de.isContainsRemovedComponentIds(ids: dbArray![i][j])) {
                    
                    erasedComponentIds.append(contentsOf: de.getNotRemovedComponentIds(ids: dbArray![i][j]))
                    //erase(erasedComponentIds: de.getNotRemovedComponentIds(ids: dbArray![i][j]))
                    de.addRemovedComponentIds(ids: de.getNotRemovedComponentIds(ids: dbArray![i][j]))
                    print("erased stroke ids = \(erasedComponentIds)")
                }
                }
            }
            }
        }
        
        if erasedComponentIds.count != 0 {
            erasedComponentIds.sort()
            erase(erasedComponentIds: erasedComponentIds)
        }
    }
    
    func erase(erasedComponentIds: [Int]) {
        print("erasedIds = \(erasedComponentIds)")
        
        //publish
        //sendMqttMessage.putMqttMessage(messageFormat: MqttMessageFormat(username: de.myUsername!, mode: Mode.ERASE, componentIds: NSArray(array: erasedComponentIds, copyItems: true) as! [Int]))
        sendMqttMessage.putMqttMessage(messageFormat: MqttMessageFormat(username: de.myUsername!, mode: Mode.ERASE, componentIds: erasedComponentIds))
        //client.publish(topic: client.topic_data, message: parser.jsonWrite(object: messageFormat)!)
        
        eraserTask.execute(erasedComponentIds: self.erasedComponentIds)
        
        self.erasedComponentIds.removeAll()
        de.clearUndoArray()
    }
}
