//
//  MqttClient.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/05/28.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import MQTTClient

class MQTTClient: NSObject {
    public static let client = MQTTClient() // singleton

    // MQTT
    private var mqtt_host: String!
    private var mqtt_port: UInt32!
    private let qos: MQTTQosLevel = .exactlyOnce // 2
    private var transport = MQTTCFSocketTransport()
    fileprivate var session = MQTTSession()
    //
    
    // TOPIC
    private var topic: String!
    private var topic_join: String!
    private var topic_noti: String!
    private var topic_exit: String!
    private var topic_delete: String!
    private var topic_data: String!
    private var topic_mid: String!
    private var topic_audio: String!
    private var topic_alive: String!
    //
    
    private var myName: String!
    private var master: Bool!
    private var masterName: String!
    private var userList = [String]()
    private var drawingCV: DrawingViewController!
    
    // 생성자
    private override init() {
        super.init()
    }
    
    public func initialize(_ ip: String, _ port: String, _ topic: String, _ name: String, _ master: Bool, _ masterName: String, _ drawingCV: DrawingViewController) {
        connect(ip, port)
        
        self.topic = topic
        self.topic_join = topic + "_join"
        self.topic_noti = topic + "_noti"
        self.topic_exit = topic + "_exit"
        self.topic_delete = topic + "_delete"
        self.topic_data = topic + "_data"
        self.topic_mid = topic + "_mid"
        self.topic_audio = topic + "_audio"
        self.topic_alive = topic + "_alive"
        
        self.myName = name
        self.master = master
        self.masterName = masterName
        self.drawingCV = drawingCV
        
        if !self.master {
            self.userList.append(self.masterName)
        }
        self.userList.append(self.myName)
        self.drawingCV.setUserNum(userNum: userList.count)
        self.drawingCV.setNamesPrint(names: usernameList())
        
        self.subscribeAllTopics()
        
        publish(topic: topic_join, message: myName)
    }

    public func connect(_ ip: String, _ port: String) {
        session?.delegate = self
        transport.host = ip
        transport.port = UInt32(port)!
        print(UInt32(port)!)
        session?.transport = transport
        
        session?.connect() {
            error in
            if error != nil {
                print("MQTT : Connection Failed ... [\(String(describing: error))]")
            } else {
                print("MQTT : Connection Success !!!")
            }
        }
    }

    public func subscribe(_ topic: String) {
        session?.subscribe(toTopic: topic, at: qos) {
            error, result in
            if error != nil {
                print("MQTT : Subscribe '\(topic)' Failed ... [\(String(describing: error))]")
            } else {
                print("MQTT : Subscribed to \(topic)")
            }
        }
    }
    
    public func unsubscribe(_ topic: String) {
        session?.unsubscribeTopic(topic) {
            error in
            if error != nil {
                print("MQTT : Unsubscribe '\(topic)' Failed ... [\(String(describing: error))]")
            } else {
                print("MQTT : Unsubscribed to \(topic)")
            }
        }
    }

    public func publish(topic: String, message: String) {
        session?.publishData(message.data(using: .utf8), onTopic: topic, retain: false, qos: qos)
        print("pub: \(message)")
    }
    
    public func subscribeAllTopics() {
        subscribe(topic_join)
        subscribe(topic_noti)
        subscribe(topic_exit)
        subscribe(topic_delete)
        subscribe(topic_data)
        subscribe(topic_mid)
        subscribe(topic_alive)
    }
    
    public func unsubscribeAllTopics() {
        unsubscribe(topic_join)
        unsubscribe(topic_noti)
        unsubscribe(topic_exit)
        unsubscribe(topic_delete)
        unsubscribe(topic_data)
        unsubscribe(topic_mid)
        unsubscribe(topic_alive)
    }
    
    public func exitTask() {
        if master {
            publish(topic: topic_delete, message: myName)
        } else {
            publish(topic: topic_exit, message: myName)
        }
        userList.removeAll()
    }
    
    public func usernameList() -> String {
        var names = ""
        for i in 0..<userList.count {
            if userList[i] == myName, master {
                names += "\(userList[i]) * (me)\n"
            } else if userList[i] == masterName {
                names += "\(userList[i]) *\n"
            } else if userList[i] == myName, !master {
                names += "\(userList[i]) (me)\n"
            } else {
                names += "\(userList[i]) \n"
            }
        }
        return names
    }
}

extension MQTTClient: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    // callback
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        let message = String(data: data, encoding: .utf8)!
        
        if (topic == topic_join) {
            print("TOPIC_JOIN : \(message)")
            if !userList.contains(message) {
                userList.append(message)
                publish(topic: topic_noti, message: myName)
                drawingCV.setUserNum(userNum: userList.count)
                drawingCV.setNamesPrint(names: usernameList())
            }
        }
        
        if (topic == topic_noti) {
            print("TOPIC_NOTI : \(message)")
            if !userList.contains(message) {
                userList.append(message)
                drawingCV.setUserNum(userNum: userList.count)
                drawingCV.setNamesPrint(names: usernameList())
            }
        }
        
        if (topic == topic_exit) {
            print("TOPIC_EXIT : \(message)")
            for i in 0..<userList.count {
                if userList[i] == message {
                    userList.remove(at: i)
                    drawingCV.setUserNum(userNum: userList.count)
                    drawingCV.setNamesPrint(names: usernameList())
                }
            }
        }
        
        if (topic == topic_delete) {
            print("TOPIC_DELETE : \(message)")
        }
        
        if (topic == topic_data) {
            print("TOPIC_DATA : \(message)")
        }
        
        if (topic == topic_mid) {
            print("TOPIC_MID : \(message)")
        }
        
        if (topic == topic_audio) {
            print("TOPIC_AUDIO : \(message)")
        }
        
        if (topic == topic_alive) {
            print("TOPIC_ALIVE : \(message)")
        }
    }
}
