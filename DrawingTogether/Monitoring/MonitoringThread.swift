//
//  MonitoringThread.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/10/27.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class MonitoringThread: Thread {
    
    var client: MQTTClient!
    var second: TimeInterval!
    
    override init() {
        super.init()
        self.client = MQTTClient.client
        self.second = 3.0
    }
    
    override func main() {
        
        let jsonParser = JSONParser.parser
        let topic = client.topic_monitoring!
        
        print("monitoring: wait... topic record save");
        Thread.sleep(forTimeInterval: second);
        print("monitoring: enable monitoring thread!!")
        
        while true {
            if isCancelled {
                print("monitoring thread is dead")
                break
            }
            
            if let componentCount = client.componentCount {
                let mmf = MqttMessageFormat(componentCount: componentCount)
                //print("monitoring mqtt message format = " + jsonParser.jsonWrite(object: mmf)!)
                
                self.client.publish(topic: topic, message: jsonParser.jsonWrite(object: mmf)!)
                //print("publish monitoring message")
                
                Thread.sleep(forTimeInterval: self.second)
            }
        }
    }
    
}
