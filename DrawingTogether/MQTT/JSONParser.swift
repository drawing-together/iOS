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
    
    var drawingVC: DrawingViewController!
    
    func jsonWrite(object: MqttMessageFormat) -> String? {
        
//        if let data = try? JSONParser.encoder.encode(object) {
//            //print("success MqttMessageFormat to JsonString")
//            return String(data: data, encoding: .utf8)!
//        }
//
//        print("failed MqttMessageFormat to JsonString")
//        return nil
        
        do {
            let data = try JSONParser.encoder.encode(object)
            return String(data: data, encoding: .utf8)!
        } catch {
            print(error)
        }
        
        return nil
        
    }
    
    func jsonReader(msg: String) -> MqttMessageFormat? {
        if let data = msg.data(using: .utf8) {
            do {
                let mqttMessageFormat = try JSONParser.decoder.decode(MqttMessageFormat.self, from: data)
                
                return mqttMessageFormat
            } catch {
                print(error)
            }
//            } catch let DecodingError.dataCorrupted(context) {
//                print(context)
//            } catch let DecodingError.keyNotFound(key, context) {
//                print("Key '\(key)' not found:", context.debugDescription)
//                print("codingPath:", context.codingPath)
//            } catch let DecodingError.valueNotFound(value, context) {
//                print("Value '\(value)' not found:", context.debugDescription)
//                print("codingPath:", context.codingPath)
//            } catch let DecodingError.typeMismatch(type, context)  {
//                print("Type '\(type)' mismatch:", context.debugDescription)
//                print("codingPath:", context.codingPath)
//            } catch {
//                print("error: ", error)
//            }
        }
        return nil
    }
    
    
    func createDrawingComponent(dc: DrawingComponent) -> DrawingComponent? {
        if let data = try? JSONParser.encoder.encode(dc) {
            //print("success DrawingComponent to JsonString")
            
            switch dc.type {
            case .STROKE:
                return try? JSONParser.decoder.decode(Stroke.self, from: data)
            case .RECT:
                return try? JSONParser.decoder.decode(Rect.self, from: data)
            case .OVAL:
                return try? JSONParser.decoder.decode(Oval.self, from: data)
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
            adapter.CLASSNAME = String(describing: components[idx]).components(separatedBy: ".").last!
            adapter.OBJECT = components[idx]
            
            adapters.append(adapter)
        }
        
        return adapters
    }
    
    func getDrawingComponentAdapter(component: DrawingComponent) -> DrawingComponentAdapter {
        let adapter = DrawingComponentAdapter()
        adapter.CLASSNAME = String(describing: component).components(separatedBy: ".").last!
        adapter.OBJECT = component
        return adapter
    }
    
    
    func getTexts(textAdapters: [TextAdapter]) -> [Text] {
        var texts: [Text] = []
        
        for idx in 0..<textAdapters.count {
            
            let text = Text()
            text.create(textAttribute: textAdapters[idx].textAttr!, drawingVC: drawingVC)
            
            texts.append(text)
        }
        
        return texts
    }
    
    func getTextAdapters(texts: [Text]) -> [TextAdapter] {
        var textAdapters: [TextAdapter] = []
        
        for idx in 0..<texts.count {
            textAdapters.append(TextAdapter())
            textAdapters[idx].textAttr = texts[idx].textAttribute
        }
        
        return textAdapters
    }
    
}
