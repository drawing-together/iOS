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
    private var userList = [User]()
    private var drawingVC: DrawingViewController!
    
    // DRAWING
    private var parser: JSONParser = JSONParser.parser
    private var de: DrawingEditor = DrawingEditor.INSTANCE
    
    // AUDIO
    private var audioPlaying: Bool = false

    // 생성자
    private override init() {
        super.init()
    }
    
    public func initialize(_ ip: String, _ port: String, _ topic: String, _ name: String, _ master: Bool, _ masterName: String, _ drawingVC: DrawingViewController) {
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
        self.drawingVC = drawingVC
        
        if !self.master {
            let user = User(name: masterName, count: 0, action: -1, isInitialized: false)
            self.userList.append(user)
        }
        let user = User(name: myName, count: 0, action: -1, isInitialized: false)
        self.userList.append(user)
        self.drawingVC.setUserNum(userNum: userList.count)
        drawingVC.userListStr = usernameList()
        
        connect(ip, port) { (result) in
            if result == "success" {
                self.subscribeAllTopics()
                let joinMessage = JoinMessage(name: self.myName)
                let messageFormat = MqttMessageFormat(joinMessage: joinMessage)
                let jsonParser = JSONParser()
                self.publish(topic: self.topic_join, message: jsonParser.jsonWrite(object: messageFormat)!)
            }
            else {
                self.drawingVC.showAlert(title: "MQTT Connection Failed", message: result, selectable: false)
            }
        }
    }

    public func connect(_ ip: String, _ port: String, _ handler: @escaping(String) -> Void) {
        session?.delegate = self
        transport.host = ip
        transport.port = UInt32(port)!
        print(UInt32(port)!)
        session?.transport = transport
        
        session?.connect() {
            error in
            if error != nil {
                print("MQTT : Connection Failed ... [\(String(describing: error))]")
                handler(String(describing: error))
            } else {
                print("MQTT : Connection Success !!!")
                handler("success")
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
        print("pub: \(topic) \(message)")
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
            let deleteMessage = DeleteMessage(name: self.myName)
            let messageFormat = MqttMessageFormat(deleteMessage: deleteMessage)
            let jsonParser = JSONParser()
            publish(topic: self.topic_delete, message: jsonParser.jsonWrite(object: messageFormat)!)
        } else {
            let exitMessage = ExitMessage(name: self.myName)
            let messageFormat = MqttMessageFormat(exitMessage: exitMessage)
            let jsonParser = JSONParser()
            publish(topic: self.topic_exit, message: jsonParser.jsonWrite(object: messageFormat)!)
        }
        userList.removeAll()
        
        // 오디오 처리 - 수정 필요
        if drawingVC.speakerFlag {
            unsubscribe(topic_audio)
            audioPlaying = false
        }
        //
    }
    
    public func usernameList() -> String {
        var names = ""
        for i in 0..<userList.count {
            if userList[i].name == myName, master {
                names += "\(userList[i].name!) ★ (나)\n"
            } else if userList[i].name == masterName {
                names += "\(userList[i].name!) ★\n"
            } else if userList[i].name == myName, !master {
                names += "\(userList[i].name!) (나)\n"
            } else {
                names += "\(userList[i].name!) \n"
            }
        }
        return names
    }
    
    public func isContainsUserList(name: String) -> Bool {
        for user in userList {
            if user.name == name {
                return true
            }
        }
        return false
    }
}

extension MQTTClient: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    // callback
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        let message = String(data: data, encoding: .utf8)!
        print("Message \(message)")
        //let jsonParser = JSONParser()
        let mqttMessageFormat = parser.jsonReader(msg: message)!
        
        
        if (topic == topic_join) {
            print("TOPIC_JOIN : \(message)")
            let joinMessage = mqttMessageFormat.joinMessage
            if joinMessage?.master != nil {
                // intercept
                
                if let to = joinMessage?.to, to == myName {
                    de.drawingComponents = parser.getDrawingComponents(adapters: mqttMessageFormat.drawingComponents!)
                    print("mid \(de.drawingComponents.count)")
                }
            }
            else if let joinName = joinMessage?.name, myName != joinName {
                if !isContainsUserList(name: joinName) {
                    let user = User(name: joinName, count: 0, action: -1, isInitialized: false)
                    userList.append(user)
                    drawingVC.setUserNum(userNum: userList.count)
                    drawingVC.userListStr = usernameList()
                    
                    let notiMessage = NotiMessage(name: myName)
                    let messageFormat = MqttMessageFormat(notiMessage: notiMessage)
                    let jsonParser = JSONParser()
                    publish(topic: topic_noti, message: jsonParser.jsonWrite(object: messageFormat)!)
                }
                if master {
                    // all action up
                    // republish
                }
            }
        }
        
        if (topic == topic_noti) {
            print("TOPIC_NOTI : \(message)")
            let notiMessage = mqttMessageFormat.notiMessage
            var notiName: String!
            if let name = notiMessage?.name {
                notiName = name
                print(notiName)
            }
            if !isContainsUserList(name: notiName) {
                let user = User(name: notiName, count: 0, action: -1, isInitialized: false)
                userList.append(user)
                drawingVC.setUserNum(userNum: userList.count)
                drawingVC.userListStr = usernameList()
            }
        }
        
        if (topic == topic_exit) {
            print("TOPIC_EXIT : \(message)")
            let exitMessage = mqttMessageFormat.exitMessage
            var exitName: String!
            if let name = exitMessage?.name {
                exitName = name
                print(exitName)
            }
            for i in 0..<userList.count {
                if userList[i].name == exitName {
                    userList.remove(at: i)
                    drawingVC.setUserNum(userNum: userList.count)
                    drawingVC.userListStr = usernameList()
                    break
                }
            }
        }
        
        if (topic == topic_delete) {
            print("TOPIC_DELETE : \(message)")
            let deleteMessage = mqttMessageFormat.deleteMessage
            var deleteName: String!
            if let name = deleteMessage?.name {
                deleteName = name
                print(deleteName)
            }
            if deleteName != myName {
                OperationQueue.main.addOperation {
                    self.drawingVC.showAlert(title: "토픽 종료", message: "master가 토픽을 종료하였습니다.", selectable: false)
                }
            }
        }
        
        if (topic == topic_data) {
            print("TOPIC_DATA : \(message)")
            
            let dc = mqttMessageFormat.component?.getComponent() // componentAdapter.getComponent()

            if dc is Stroke {
                print("stroke parsing ok")
            }

            if dc is Rect {
                print("rect parsing ok")
            }
            
        }
        
        if (topic == topic_mid) {
            print("TOPIC_MID : \(message)")
        }
        
        if (topic == topic_audio) {
            print("TOPIC_AUDIO : \(message)")
            
            if (!audioPlaying && drawingVC.speakerFlag) { // Audio Start
                audioPlaying = true
                // 오디오 처리
            } else if (audioPlaying && !drawingVC.speakerFlag) { // Audio Stop
                // 오디오 처리
                audioPlaying = false
                unsubscribe(topic_audio)
            }
        }
        
        if (topic == topic_alive) {
            print("TOPIC_ALIVE : \(message)")
        }
    }
}
