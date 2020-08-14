//
//  ObserveThread.swift
//  DrawingTogether
//
//  Created by admin on 2020/08/14.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class ObserveThread: Thread {
    
    var mqttClient: MQTTClient!
    var lastPubTime: Date!
    var isPubed: Bool!
    
    override init() {
        super.init()
        self.mqttClient = MQTTClient.client
        self.isPubed = false
    }
    
    override func main() {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        lastPubTime = formatter.date(from: formatter.string(from: Date()))
        
        while true {
            
            if isPubed {
                lastPubTime = formatter.date(from: formatter.string(from: Date()))
                print(lastPubTime)
                isPubed = false
                
            }
            if lastPubTime.timeIntervalSinceNow < -10.0 {
                OperationQueue.main.addOperation {
                    self.mqttClient.drawingVC.showAlert(title: "non response", message: "1 minute passed", selectable: false)
                    
                }
                
                break
            }
        }
    }
    
}
