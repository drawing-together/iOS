//
//  AliveThread.swift
//  DrawingTogether
//
//  Created by admin on 2020/07/12.
//  Copyright © 2020 hansung. All rights reserved.
//
import Foundation

class AliveThread: Thread {
    
    var mqttClient: MQTTClient!
    var topic: String!
    var myName: String!
    var second: TimeInterval!
    
    override init() {
        super.init()
        self.mqttClient = MQTTClient.client
        self.topic = self.mqttClient.getTopic()
        self.myName = self.mqttClient.getMyName()
        self.second = 2.0
    }
    
    override func main() {
        let aliveMessage = AliveMessage(name: self.myName)
        let messageFormat = MqttMessageFormat(aliveMessage: aliveMessage)
        let jsonParser = JSONParser.parser
        
        while true {
            if isCancelled {
                break
            }
            self.mqttClient.publish(topic: topic + "_alive", message: jsonParser.jsonWrite(object: messageFormat)!)
            Thread.sleep(forTimeInterval: self.second)
        }
    }
    
    // setter
    public func setSecond(second: TimeInterval) {
        self.second = second
    }
    
}
