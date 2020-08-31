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
    var erasedComponentIds: [Int]!
    
    func findComponentsToErase(eraserPoint: Point) {
        erasedComponentIds = [Int]()
        erasedComponentIds!.append(-1)

        let x = eraserPoint.x
        let y = eraserPoint.y

        //print("\(x), \(y)")
        
        let dbArray = de.drawingBoardArray

        if(y-squareScope<0 || x-squareScope<0 || y+squareScope>Int(de.myCanvasHeight!) || x+squareScope>Int(de.myCanvasWidth!)) {
            print("eraser exit")
            return
        }

        //for i in (y-squareScope)..<(y+squareScope) {
        for i in stride(from: (y-squareScope), through: (y+squareScope), by: 1) {
            //for j in (x-squareScope)..<(x+squareScope) {
            for j in stride(from: (x-squareScope), through: (x+squareScope), by: 1) {
                let shapeIds = de.findEnclosingDrawingComponents(point: eraserPoint)
                if shapeIds.count != 1 && !de.isContainsRemovedComponentIds(ids: shapeIds) {
                    erasedComponentIds?.append(contentsOf: shapeIds)
                    de.addRemovedComponentIds(ids: shapeIds)
                    print("erased shape ids = \(erasedComponentIds!)")
                    //erase(erasedComponentIds)
                }

                /*var str = "(\(x),\(y)), dbArray[\(i)][\(j)] = "
                for component in dbArray![i][j] {
                    str += "\(component) "
                }
                print(str)*/
                
                if(dbArray![i][j].count != 1 && !de.isContainsRemovedComponentIds(ids: dbArray![i][j])) { //-1만 가지고 있으면 size() == 1
                    //erasedComponentIds = (dbArray[i][j]);
                    erasedComponentIds?.append(contentsOf: de.getNotRemovedComponentIds(ids: dbArray![i][j]))
                    de.addRemovedComponentIds(ids: de.getNotRemovedComponentIds(ids: dbArray![i][j]))
                    print("erased stroke ids = \(erasedComponentIds!)")

                    /*if(de.findEnclosingDrawingComponents(eraserPoint).size() != 1) {
                        erasedComponentIds.addAll(de.findEnclosingDrawingComponents(eraserPoint));
                    }*/
                }

            }
        }

        if erasedComponentIds!.count != 1 {
            erasedComponentIds!.sort()
            erase(erasedComponentIds: erasedComponentIds!)
        }
    }

    func erase(erasedComponentIds: [Int]) {
        print("erasedIds = \(erasedComponentIds)")

        //publish
        let messageFormat = MqttMessageFormat(username: de.myUsername!, mode: Mode.ERASE, componentIds: NSArray(array: erasedComponentIds, copyItems: true) as! [Int])
        sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
        //client.publish(topic: client.topic_data, message: parser.jsonWrite(object: messageFormat)!)

        EraserTask(erasedComponentIds: erasedComponentIds).execute()
        self.erasedComponentIds!.removeAll()
        de.clearUndoArray()
    }
}
