//
//  JSONParser.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/04.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

class JSONParser {
    static let parser = JSONParser()
    private init() {}
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
            
            print("success JsonString to MqttMessageFormat")
            return mqttMessageFormat
        }
        
        print("failed JsonString to MqttMessageFormat")
        return nil
    }
    
    func createDrawingComponent(dc: DrawingComponent) -> DrawingComponent? {
        if let data = try? JSONParser.encoder.encode(dc) {
            print("success DrawingComponent to JsonString")
            
            switch dc.type {
            case .STROKE:
                return try? JSONParser.decoder.decode(Stroke.self, from: data)
            case .RECT:
                return try? JSONParser.decoder.decode(Rect.self, from: data)
            default:
                print("?")
            }
            
        }
        
        return nil
    }
    
    func getDrawingComponents(adapters: [DrawingComponentAdapter]) -> [DrawingComponent] {
        
        var dcs: [DrawingComponent] = []
        
        for idx in 0..<adapters.count {
            dcs.append(adapters[idx].getComponent()!)
        }
        
        return dcs
    }
    
    func getDrawingComponentAdapters(components: [DrawingComponent]) -> [DrawingComponentAdapter] {
        var adapters: [DrawingComponentAdapter] = []
        
        for idx in 0..<components.count {
            let adapter = DrawingComponentAdapter()
            adapter.CLASSNAME = String(describing: components[idx])
            adapter.OBJECT = components[idx]
            
            adapters.append(adapter)
        }
        
        return adapters
    }
    
    func getDrawingComponentAdapter(component: DrawingComponent) -> DrawingComponentAdapter {
        let adapter = DrawingComponentAdapter()
        adapter.CLASSNAME = String(describing: component)
        adapter.OBJECT = component
        return adapter
    }
    
    
}
