//
//  SendMqttMessage.swift
//  DrawingTogether
//
//  Created by MJ B on 2020/07/17.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class SendMqttMessage: Thread {
    static let INSTANCE = SendMqttMessage()
    
    var client = MQTTClient.client
    var parser = JSONParser.parser
    var messageQueue: CircularQueue!
    
    let semaphore = DispatchSemaphore(value: 0)
    let queue = DispatchQueue(label: "sendThreadQueue") //, qos: .background)
    
    var putCnt = 0
    var takeCnt = 0
    
    override private init() {
        messageQueue = CircularQueue(capacity: 10000)
        
    }
    
    func putMqttMessage(messageFormat: MqttMessageFormat) {
        //self.semaphore.signal()
        queue.async {
            
            if self.messageQueue.offer(value: messageFormat) {
                self.putCnt += 1
                //print("msgQueue offer success \(self.putCnt), queue size=\(self.messageQueue.capacity)")
                self.semaphore.signal()
            } else {
                print("msgQueue is FULL!")
                self.semaphore.wait()
            }
        }
    }
    
    func startThread() {
        if (self.isExecuting) {
            print("sendThread is running")
        } else {
            self.start()
            print("sendThread start")
        }
    }
    
    override func main() {
        while(true) {
    
            if self.messageQueue.isEmpty() {
                //print("msgQueue messageFormat is nil")
                self.semaphore.wait()
            } else {
                self.semaphore.signal()
                queue.async {
                    if let messageFormat = self.messageQueue.poll() {
                        self.client.publish(topic: self.client.topic_data, message: self.parser.jsonWrite(object: messageFormat)!)
                        
                        self.takeCnt += 1
                        //print("msgQueue poll success \(self.takeCnt), queue size=\(self.messageQueue.capacity)")
                    } /*else {
                     print("msgQueue poll failed, queue size=\(self.messageQueue.capacity)")
                     }*/
                }

            }
            
        }
        
    }
    
}


