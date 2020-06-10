//
//  JSONParser.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/04.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation

class JSONParser {
    static let parser = JSONParser()
    init() {}
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    
    func jsonWrite(object: MqttMessageFormat) -> String? {
        
        if let data = try? JSONParser.encoder.encode(object) {
            print("success MqttMessageFormat to JsonString")
            return String(data: data, encoding: .utf8)!
        }
        
        print("failed MqttMessageFormat to JsonString")
        return nil
        
    }
    
    func jsonReader(msg: String) -> MqttMessageFormat? {
        if let data = msg.data(using: .utf8), let mqttMessageFormat = try? JSONParser.decoder.decode(MqttMessageFormat.self, from: data) {
            
            print("JsonString to MqttMessageFormat")
            return mqttMessageFormat
        }
        
        print("failed JsonString to MqttMessageFormat")
        return nil
    }
    
//    func createDrawingComponent(dc: DrawingComponent) -> String {
//
//    }
    
}
