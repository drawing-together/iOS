//
//  MqttClient.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/05/28.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import MQTTClient
import SVProgressHUD
import SDWebImageSVGCoder

class MQTTClient: NSObject {
    public static let client = MQTTClient() // singleton
    public static let client2 = MQTTClient() // only pub
    
    // MQTT
    var mqtt_host: String!
    var mqtt_port: UInt32!
    let qos: MQTTQosLevel = .exactlyOnce // 2
    var transport = MQTTCFSocketTransport()
    var session = MQTTSession()
    //
    
    // TOPIC
    var topic: String!
    var topic_join: String!
    var topic_exit: String!
    var topic_close: String!
    var topic_data: String!
    var topic_mid: String!
    var topic_audio: String!
    var topic_image: String!
    var topic_alive: String!
    var topic_monitoring: String!
    //
    
    var myName: String!
    var master: Bool!
    var masterName: String!
    var userList = [User]()
    var drawingVC: DrawingViewController!
    
    // DRAWING
    private var parser: JSONParser = JSONParser.parser
    private var de: DrawingEditor = DrawingEditor.INSTANCE
    var isMid = true
    let queue = DispatchQueue(label: "drawingQueue")
    var eraserTask = EraserTask()
    var totalMoveX = 0
    var totalMoveY = 0
    
    // AUDIO
    private var audioPlaying: Bool = false
    
    // ALIVE
    private var aliveThread: AliveThread!
    private var aliveLimitCount: Int!
    
    // MONITORING
    var componentCount: ComponentCount?
    var monitoringThread: MonitoringThread?
    
    // 생성자
    private override init() {
        super.init()
    }
    
    public func initialize(_ ip: String, _ port: String, _ topic: String, _ name: String, _ master: Bool, _ masterName: String, _ drawingVC: DrawingViewController) {
        self.topic = topic
        self.topic_join = topic + "_join"
        self.topic_exit = topic + "_exit"
        self.topic_close = topic + "_close"
        self.topic_data = topic + "_data"
        self.topic_mid = topic + "_mid"
        self.topic_audio = topic + "_audio"
        self.topic_image = topic + "_image"
        self.topic_alive = topic + "_alive"
        self.topic_monitoring = "monitoring"
        
        self.myName = name
        self.master = master
        self.masterName = masterName
        self.drawingVC = drawingVC
        self.aliveLimitCount = 5
        
        if !self.master {
            let user = User(name: masterName, count: 0, action: MotionEvent.ACTION_UP.rawValue, isInitialized: false)
            self.userList.append(user)
        }
        let user = User(name: myName, count: 0, action: MotionEvent.ACTION_UP.rawValue, isInitialized: false)
        self.userList.append(user)
        setUserNumAndNames()
        
        connect(ip, port) { (result) in
            if result == "success" {
                self.subscribeAllTopics()
                let joinMessage = JoinMessage(name: self.myName)
                let messageFormat = MqttMessageFormat(joinMessage: joinMessage)
                self.publish(topic: self.topic_join, message: self.parser.jsonWrite(object: messageFormat)!)

                self.aliveThread = AliveThread()
                self.aliveThread.setSecond(second: 10.0)
                self.aliveThread.start()
            }
            else {
                self.drawingVC.showAlert(title: "MQTT Connection Failed", message: result, selectable: false)
            }
        }
        
        MQTTClient.client2.connect(ip, port) { (result) in
            if result == "success" {
                print("MQTT client in callback Connection Success")
            }
            else {
                self.drawingVC.showAlert(title: "MQTT client in callback Connection Failed", message: result, selectable: false)
            }
        }
        
        de.myUsername = name
    }
    
    public func connect(_ ip: String, _ port: String, _ handler: @escaping(String) -> Void) {
        session?.delegate = self
        transport.host = ip
        transport.port = UInt32(port)!
        print(UInt32(port)!)
        session?.transport = transport
        
        // MARK: SET MQTT CLINET NAME
        // client일 경우 client id를 지정함으로써 브로커 로그에 사용자가 메인 화면에서 입력한 이름이 출력되도록 설정 (clientInCallback의 경우 해당 X)
        if let clientName = self.myName, let topic = self.topic {
            self.session!.clientId = "*\(clientName)_\(topic)_iOS"
        }
        
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
    }
    
    public func publish(topic: String, message: [Int8]) {
        session?.publishData(NSData(bytes: message, length: message.count) as Data, onTopic: topic, retain: false, qos: qos)
    }
    
    
    public func subscribeAllTopics() {
        subscribe(topic_join)
        subscribe(topic_exit)
        subscribe(topic_close)
        subscribe(topic_data)
        subscribe(topic_mid)
        subscribe(topic_image)
        subscribe(topic_alive)
    }
    
    public func unsubscribeAllTopics() {
        unsubscribe(topic_join)
        unsubscribe(topic_exit)
        unsubscribe(topic_close)
        unsubscribe(topic_data)
        unsubscribe(topic_mid)
        unsubscribe(topic_image)
        unsubscribe(topic_alive)
    }
    
    public func exitTask() {
        print("exit task start")
        if master {
            let closeMessage = CloseMessage(name: self.myName)
            let messageFormat = MqttMessageFormat(closeMessage: closeMessage)
            publish(topic: self.topic_close, message: self.parser.jsonWrite(object: messageFormat)!)
        } else {
            let exitMessage = ExitMessage(name: self.myName)
            let messageFormat = MqttMessageFormat(exitMessage: exitMessage)
            publish(topic: self.topic_exit, message: self.parser.jsonWrite(object: messageFormat)!)
        }
        userList.removeAll()
        
        aliveThread.cancel()
        if master {
            monitoringThread!.cancel()
        }
        
        de.removeAllDrawingData()
        isMid = true
        
        // 오디오 처리 - 수정 필요
//        if drawingVC.speakerFlag {
//            unsubscribe(topic_audio)
//            audioPlaying = false
//        }
        //
        print("exit task end")
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
    
    public func setUserNumAndNames() {
        drawingVC.setUserNum(userNum: userList.count)
        drawingVC.userListStr = usernameList()
        
        if drawingVC.userVC.isViewLoaded {
            print("userVC viewLoaded")
            drawingVC.userVC.userLabel.text = usernameList()
        }
    }
    
    public func isContainsUserList(name: String) -> Bool {
        for user in userList {
            if user.name == name {
                return true
            }
        }
        return false
    }
    
    public func updateUsersAction(username: String, action: Int) {
        for user in userList {
            if user.name == username {
                user.action = action
                if action == MotionEvent.ACTION_UP.rawValue {
                    print("update \(username) action UP")
                }
            }
        }
    }
    
    public func isUsersActionUp(username: String) -> Bool {
        for user in userList {
            if user.name == nil || user.action == nil  { return false }
            
            if user.name != username && user.action != MotionEvent.ACTION_UP.rawValue { return false }
        }
        
        var str = ""
        for user in userList {
            if user.name != username {
                str += "[\(user.name!), \(MotionEvent.actionToString(action: user.action!))] "
            }
        }
        print("users action = \(str)")
        
        return true
    }
    
    public func isTextInUse() -> Bool {
        print("text: in isTextInUse func")
        
        for text in de.texts {
            if text.textAttribute.isDragging { // 다른 참가자들이 텍스트를 드래그 중일 때 드래그가 완료될 때 까지 기다림
                return true
            }
        }
        return false
    }
    
    
    
    // GETTER
    public func getTopic() -> String { return self.topic }
    
    public func getMyName() -> String { return self.myName }
    
    // MONITORING
    
    func checkComponentCount(mode: Mode?, type: ComponentType?, textMode: TextMode?) {
        // print("monitoring: " + "execute check component count func.");
        
        if(mode! == Mode.DRAW) {
            // print("monitoring: " + "check component count func. mode is DRAW");
            
            switch (type!) {
            case .STROKE:
                    componentCount!.increaseStroke();
                    break;
            case .RECT:
                    componentCount!.increaseRect();
                    break;
            case .OVAL:
                    componentCount!.increaseOval();
                    break;
            }
            return;
        }

        if(mode! == Mode.TEXT && textMode! == TextMode.CREATE) {
            // print("monitoring:" + "check component count func. text count increase.");

            componentCount!.increaseText();
            return;
        }
   
    }
    
}

extension MQTTClient: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    // callback
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        
        if (topic == topic_image) {
            let imageData = data.map { Int8(bitPattern: $0) }
            de.backgroundImage = imageData
            
            drawingVC.backgroundImageView.image = de.convertByteArray2UIImage(byteArray: de.backgroundImage!)
            
            if(master) {
                componentCount!.increaseImage()
            }
            
            return
        }
        
        if (topic == topic_audio) {
            return
            //            if (!audioPlaying && drawingVC.speakerFlag) { // Audio Start
            //                audioPlaying = true
            //                // 오디오 처리
            //            } else if (audioPlaying && !drawingVC.speakerFlag) { // Audio Stop
            //                // 오디오 처리
            //                audioPlaying = false
            //                unsubscribe(topic_audio)
            //            }
                    }
        
        let message = String(data: data, encoding: .utf8)!
        //print(message)
        
        if parser.jsonReader(msg: message) == nil { return }
        let mqttMessageFormat = parser.jsonReader(msg: message)!
        
        if (topic == topic_join) {
            let joinMessage = mqttMessageFormat.joinMessage
            let joinAckMessage = mqttMessageFormat.joinAckMessage
            
            if joinMessage != nil {
                if let joinName = joinMessage?.name, joinName != myName {
                    
                     if !isContainsUserList(name: joinName) {
                        
                        let user = User(name: joinName, count: 0, action: MotionEvent.ACTION_UP.rawValue, isInitialized: false)
                        self.userList.append(user)
                                               
                        if !master {
                            let joinAckMsg = JoinAckMessage(name: myName, target: joinName)
                            let msgFormat = MqttMessageFormat(joinAckMessage: joinAckMsg)
                            MQTTClient.client2.publish(topic: topic_join, message: parser.jsonWrite(object: msgFormat)!)
                        }
                                               
                        de.isMidEntered = true
                           
                        de.isIntercept = true
                        if !drawingVC.drawingView!.isMovable {
                            drawingVC.drawingView.isIntercept = true
                        }
                                               
                        drawingVC.showToast(message: "[ \(joinName) ] 님이 접속하셨습니다")
                        setUserNumAndNames()
                        
                    }
                    if master {
                         if isUsersActionUp(username: joinName) && !isTextInUse() {
                            let joinAckMsg = JoinAckMessage(name: myName, target: joinName)
                            
//                            var messageFormat: MqttMessageFormat?
//                            // 배경 이미지가 없는 경우
//                            if de.backgroundImage == nil {
//                                messageFormat = MqttMessageFormat(joinAckMessage: joinAckMsg, drawingComponents: parser.getDrawingComponentAdapters(components: de.drawingComponents), texts: parser.getTextAdapters(texts: de.texts), history: de.history, undoArray: de.undoArray, removedComponentId: de.removedComponentId, maxComponentId: de.maxComponentId, maxTextId: de.maxTextId);
//
//                            }
//                            // 배경 이미지가 있는 경우
//                            else {
//                                messageFormat = MqttMessageFormat(joinAckMessage: joinAckMsg, drawingComponents: parser.getDrawingComponentAdapters(components: de.drawingComponents), texts: parser.getTextAdapters(texts: de.texts), history: de.history, undoArray: de.undoArray, removedComponentId: de.removedComponentId, maxComponentId: de.maxComponentId, maxTextId: de.maxTextId, bitmapByteArray: de.bitmapByteArray!);
//                            }
                            
                            let messageFormat = MqttMessageFormat(joinAckMessage: joinAckMsg, drawingComponents:parser.getDrawingComponentAdapters(components: de.drawingComponents), texts:parser.getTextAdapters(texts: de.texts), history: de.history, undoArray: de.undoArray,removedComponentId: de.removedComponentId, maxComponentId: de.maxComponentId, maxTextId: de.maxTextId, autoDrawList: de.autoDrawList);
                            let json = parser.jsonWrite(object: messageFormat);
                            MQTTClient.client2.publish(topic: topic_join, message: json!)
                            print("login data publish complete -> \(joinName)")
                            
                            if de.backgroundImage != nil {
                                let backgroundImage = de.backgroundImage
                                MQTTClient.client2.publish(topic: topic_image, message: backgroundImage!)
                            }
                            
                            drawingVC.showToast(message: "[ \(joinName) ] 님에게 데이터 전송을 완료했습니다")
                            print("\(joinName) join 후 : \(userList)");
                            
                        }
                         else {
                            let messageFormat = MqttMessageFormat(joinMessage: JoinMessage(name: joinName))
                            MQTTClient.client2.publish(topic: topic_join, message: parser.jsonWrite(object: messageFormat)!)
                            print("master republish name")                        }
                    }
                }
            }
            else if (joinAckMessage != nil) {
                if let joinAckName = joinAckMessage?.name, let joinAckTarget = joinAckMessage?.target, joinAckTarget == myName {
                    
                    if joinAckName == masterName {
                         // 드로잉에 필요한 필요한 배열들 세팅
                         de.drawingComponents = parser.getDrawingComponents(adapters: mqttMessageFormat.drawingComponents!)
                         print("mid \(de.drawingComponents.count)")
                         de.history = mqttMessageFormat.history!
                         de.undoArray = mqttMessageFormat.undoArray!
                         de.removedComponentId = mqttMessageFormat.removedComponentId!
                         
                         // 텍스트 세팅
                         de.texts = parser.getTexts(textAdapters: mqttMessageFormat.texts!)
                         
                         // 아이디 세팅
                         de.maxComponentId = mqttMessageFormat.maxComponentId!
                        
                         de.autoDrawList = mqttMessageFormat.autoDrawList!
                         
//                         // 배경 이미지 세팅
//                         if mqttMessageFormat.bitmapByteArray != nil {
//                             print("bitmap byte array")
//                             de.bitmapByteArray = mqttMessageFormat.bitmapByteArray!
//                         }
                         
                         MQTTClient.client2.publish(topic: topic_mid, message: parser.jsonWrite(object: MqttMessageFormat(username: myName, mode: Mode.MID))!)
                        
                    }
                    
                    else if !isContainsUserList(name: joinAckName) {
                        
                        let user = User(name: joinAckName, count: 0, action: MotionEvent.ACTION_UP.rawValue, isInitialized: false)
                        self.userList.append(user)
                        setUserNumAndNames()
                        
                    }
                }
            }
        }
        
        if (topic == topic_exit) {
            let exitMessage = mqttMessageFormat.exitMessage
            if let exitName = exitMessage?.name {
                for i in 0..<userList.count {
                    if userList[i].name == exitName {
                        userList.remove(at: i)
                        setUserNumAndNames()
                        drawingVC.showToast(message: "[ \(exitName) ] 님이 나가셨습니다.")
                        break
                    }
                }
            }
        }
        
        if (topic == topic_close) {
            let closeMessage = mqttMessageFormat.closeMessage
            if let closeName = closeMessage?.name, closeName != myName {
                drawingVC.userVC.dismiss(animated: true, completion: nil)
                self.drawingVC.showAlert(title: "회의 종료", message: "master가 회의를 종료하였습니다.", selectable: false)
            }
        }
        
        if (topic == topic_data) {
            
            if(master) { // 마스터만 컴포넌트 개수 카운트
            // 컴포넌트 개수 저장
                if (mqttMessageFormat.action != nil && mqttMessageFormat.action == MotionEvent.ACTION_DOWN.rawValue)
                    || mqttMessageFormat.mode == Mode.TEXT || mqttMessageFormat.mode == Mode.ERASE
                {
                    // print("< monitoring: mode = \(mqttMessageFormat.mode) type = \(mqttMessageFormat.type) text mode = \(mqttMessageFormat.textMode)");

                    checkComponentCount(mode: mqttMessageFormat.mode, type: mqttMessageFormat.type, textMode: mqttMessageFormat.textMode)
                }
            }
            
            // 중간 참여자가 입장했을 때 처리
            if de.isMidEntered, let action = mqttMessageFormat.action, action != MotionEvent.ACTION_UP.rawValue {
                if let usersComponentId = mqttMessageFormat.usersComponentId, (de.isIntercept && action == MotionEvent.ACTION_DOWN.rawValue), de.getCurrentComponent(usersComponentId: usersComponentId) != nil {
                    return
                }
            }
            
            switch mqttMessageFormat.mode {
            case .DRAW:
                
                self.draw(message: mqttMessageFormat)
                break
            case .ERASE:
                self.erase(message: mqttMessageFormat)
                break
            case .TEXT:
                self.text(message: mqttMessageFormat)
                break
            case .SELECT:
                 self.select(message: mqttMessageFormat)
                 break
            case .WARP:
                self.warp(message: mqttMessageFormat)
                break
            case .AUTODRAW:
                self.autoDraw(message: mqttMessageFormat)
                break
            case .CLEAR:
                self.clear(message: mqttMessageFormat)
                break
            case .CLEAR_BACKGROUND_IMAGE:
                self.clearBackgroundImage(message: mqttMessageFormat)
                break
            case .UNDO:
                self.undo(message: mqttMessageFormat)
                break
            case .REDO:
                self.redo(message: mqttMessageFormat)
                break
            case .some(_):
                break
            case .none:
                break
            }
            
        }
        
        if (topic == topic_mid) {
            if isMid, mqttMessageFormat.username == de.myUsername! {
                isMid = false
                print("mid username=\(String(describing: mqttMessageFormat.username))")
                self.mid(message: mqttMessageFormat)
            }
            
            de.isIntercept = false
            
            // 모든 사용자가 topic_mid로 메시지 전송 받음
            // 이 시점 중간자에게는 모든 데이터 저장 완료 후
            de.isMidEntered = false
        }
        
        if (topic == topic_alive) {
            //print("TOPIC_ALIVE : \(message)")
            
            let aliveMessage = mqttMessageFormat.aliveMessage
            var aliveName: String!
            if let name = aliveMessage?.name {
                aliveName = name
                //                print(aliveName)
            }
            
            if myName == aliveName {
                for (i, user) in userList.enumerated().reversed() {
                    if user.name != myName {
                        userList[i].count! += 1
                        print(user.name! + " " + String(userList[i].count!))
                        
                        if userList[i].count == aliveLimitCount && user.name == masterName {
                            drawingVC.showAlert(title: "회의방 종료", message: "마스터 접속이 끊겼습니다.\n(마스터가 alive publish를 제대로 못 한 경우 또는 마스터가 지우지 못한 회의방에 접속한 경우)", selectable: false)
                            break
                        }
                        if userList[i].count == aliveLimitCount {
                            print("[ " + user.name! + " ] 님 접속이 끊겼습니다.")
                            drawingVC.showToast(message: "[ \(user.name!) ] 님 접속이 끊겼습니다.")
                            
                            userList.remove(at: i)
                            setUserNumAndNames()
                        }
                    }
                }
            }
            else {
                for user in userList {
                    if user.name == aliveName {
                        user.count = 0
                        break
                    }
                }
            }
        }
    }
    
    
    func draw(message: MqttMessageFormat) {
        var dComponent: DrawingComponent?
        let username = message.username
        let action = message.action
        //let point = message.point //나중에 down, up에서 사용
        let myCanvasWidth = self.de.myCanvasWidth
        let myCanvasHeight = self.de.myCanvasHeight
        
        
        self.queue.async {
            //print("action=\(String(describing: action)) This is run on the background queue")
            
            if username == nil { return }
            
            if let component = message.component?.getComponent() {
                dComponent = component
                
            } else {
                if let component = self.de.getCurrentComponent(usersComponentId: message.usersComponentId!) {
                    dComponent = component
                    //print("component move, up")
                } else {
                    print("component nil")
                    return
                }
            }
            
            switch action {
                case MotionEvent.ACTION_DOWN.rawValue:
                    dComponent!.clearPoints();
                    dComponent!.id = self.de.componentIdCounter()
                    
                    self.de.addCurrentComponents(component: dComponent!)
                    self.de.printDrawingComponentArray(name: "cc", array: self.de.currentComponents, status: "down")
                    
                    self.updateUsersAction(username: username!, action: action!)
                    break
                
                case MotionEvent.ACTION_MOVE.rawValue:
                    if self.de.myUsername == username {
                        for point in message.movePoints! {
                            self.de.drawingView!.addPoint(component: dComponent!, point: point)
                        }
                    } else {
                        dComponent!.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
                        
                        //print("points[] = \(message.movePoints!)")
                        for point in message.movePoints! {
                            self.de.drawingView!.addPoint(component: dComponent!, point: point)
                        }
                            
                        
                    }
                    break
                case MotionEvent.ACTION_UP.rawValue:
                    break
                
                case .none: break
                case .some(_): break
            }
            
            DispatchQueue.main.async {
                //print("This is run on the main queue, after the previous code in outer block")
                
                switch action {
                /*case MotionEvent.ACTION_DOWN.rawValue:
                    
                    dComponent!.clearPoints();
                    dComponent!.id = self.de.componentIdCounter()
                    
                    self.de.addCurrentComponents(component: dComponent!)
                    self.de.printDrawingComponentArray(name: "cc", array: self.de.currentComponents, status: "down")
                    
                    self.updateUsersAction(username: username!, action: action!)
                    break*/
                    
                case MotionEvent.ACTION_MOVE.rawValue:
                    /*if self.de.myUsername == username {
                        for point in message.movePoints! {
                            self.de.drawingView!.addPoint(component: dComponent!, point: point)
                        }
                    } else {
                        dComponent!.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
                        
                        //print("points[] = \(message.movePoints!)")
                        for point in message.movePoints! {
                            self.de.drawingView!.addPointAndDraw(component: dComponent!, point: point, view: self.de.drawingVC!.currentView)
                        }
                    }
                    self.updateUsersAction(username: username!, action: action!)
                    break*/
                    
                    if self.de.myUsername != username {
                        dComponent!.draw(view: self.de.drawingVC!.currentView, drawingEditor: self.de)
                    }
                    //self.de.drawingVC!.currentView.setNeedsDisplay()
                    self.updateUsersAction(username: username!, action: action!)
                    break
                    
                case MotionEvent.ACTION_UP.rawValue:
                    /*if self.de.myUsername == username {
                        self.de.drawingView!.addPoint(component: dComponent!, point: message.point!)
                        self.de.drawingView?.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                        if(self.de.isIntercept) {
                            self.de.drawingView!.isIntercept = true
                            print("drawingview intercept true")
                        }
                    } else {
                        print("up \((dComponent!.username)!), \((dComponent!.id)!)")\
                        self.de.drawingView!.addPointAndDraw(component: dComponent!, point: message.point!, view: self.de.drawingVC!.currentView)
                        self.de.drawingView!.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!);
                        
                        self.drawingVC.currentView.image = nil
                        self.de.drawOthersCurrentComponent(username: dComponent?.username)
                        dComponent!.drawComponent(view: self.de.drawingView!, drawingEditor: self.de)
                    }
                    self.updateUsersAction(username: username!, action: action!);
                    break*/
                    
                    if self.de.currentMode == Mode.SELECT {
                        self.de.addPostSelectedComponent(component: dComponent!)
                    }
                    
                    if self.de.myUsername == username {
                        self.de.drawingView!.addPoint(component: dComponent!, point: message.point!)
                        self.de.drawingView?.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                        if(self.de.isIntercept) {
                            self.de.drawingView!.isIntercept = true
                            print("drawingview intercept true")
                        }
                    } else {
                        print("up \((dComponent!.username)!), \((dComponent!.id)!)")
                        self.de.drawingView!.addPointAndDraw(component: dComponent!, point: message.point!, view: self.de.drawingVC!.currentView)
                        self.de.drawingView!.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!);
                        
                        self.drawingVC.currentView.image = nil
                        self.de.drawOthersCurrentComponent(username: dComponent?.username)
                        dComponent!.drawComponent(view: self.de.drawingView!, drawingEditor: self.de)
                    }
                    //self.de.drawingVC!.currentView.setNeedsDisplay()
                    //self.de.drawingView?.setNeedsDisplay()
                    self.updateUsersAction(username: username!, action: action!);
                    break
                    
                case .none: break
                case .some(_): break
                    
                }
                
                
                
                //self.de.drawingView!.setNeedsDisplay()
                
                //client.updateUsersAction(username, action);
                
                //if de.myUsername == username { return }
                
            }
            
        }
    }
    
    func erase(message: MqttMessageFormat) {
        self.queue.async {
            if self.de.myUsername == message.username { return }
            
            print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode)), id=\(message.componentIds!)")
            let erasedComponentIds = message.componentIds!
            self.eraserTask.execute(erasedComponentIds: erasedComponentIds)
            
            DispatchQueue.main.async {
                self.de.clearUndoArray()
            }
        }
    }
    
    
    func select(message: MqttMessageFormat) {
        let myCanvasWidth = self.de.myCanvasWidth
        let myCanvasHeight = self.de.myCanvasHeight
        
        //*DispatchQueue.global(qos: .background)*/
        self.queue.async {
            if self.de.myUsername == message.username { return }
            
            if message.action == nil {
                if let selectedComponent = self.de.findDrawingComponentByUsersComponentId(usersComponentId: message.usersComponentId!), let isSelected = message.isSelected {
                    selectedComponent.isSelected = isSelected
                }
            }
            
            let selectedComponent = self.de.findDrawingComponentByUsersComponentId(usersComponentId: message.usersComponentId!)
            if selectedComponent == nil { return }
            
            print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode)), uid=\(message.usersComponentId!)")
            
            switch message.action {
            case MotionEvent.ACTION_DOWN.rawValue:
                self.totalMoveX = 0
                self.totalMoveY = 0
                print("other selected true")
                break
            case MotionEvent.ACTION_MOVE.rawValue:
                if let moveSelectPoints = message.moveSelectPoints, moveSelectPoints.count > 0 {
                    for point in moveSelectPoints {
                        self.totalMoveX += point.x
                        self.totalMoveY += point.y
                        self.de.moveSelectedComponent(selectedComponent: selectedComponent!, moveX: point.x, moveY: point.y)
                    }
                }
                break
            
            case .none:
                break
            case .some(_):
                break
            }
            
            DispatchQueue.main.async {
                
                if message.action == nil {
                    /*if message.isSelected! {
                        self.de.clearMyCurrentImage()
                        self.de.drawSelectedComponentBorder(component: selectedComponent!, color: self.de.selectedBorderColor.cgColor)
                    } else {
                        self.de.clearMyCurrentImage()
                    }*/
                } else {
                    switch message.action {
                    
                    case MotionEvent.ACTION_MOVE.rawValue:
                        //self.de.clearMyCurrentImage()
                        self.de.updateSelectedComponent(newComponent: selectedComponent!)
                        self.de.clearDrawingImage()
                        self.de.drawAllDrawingComponents()
                        
                        break
                    case MotionEvent.ACTION_UP.rawValue:
                        //self.de.clearMyCurrentImage()
                        
                        self.de.splitPointsOfSelectedComponent(component: selectedComponent!, canvasWidth: self.de.myCanvasWidth!, canvasHeight: self.de.myCanvasHeight!)
                        self.de.updateSelectedComponent(newComponent: selectedComponent!)
                        self.de.clearDrawingImage()
                        self.de.drawAllDrawingComponents()
                        
                        if let copyComponent = selectedComponent!.clone() {
                            self.de.addHistory(item: DrawingItem(mode: Mode.SELECT, component: self.parser.getDrawingComponentAdapter(component: copyComponent), movePoint: Point(x: self.totalMoveX, y: self.totalMoveY)))
                            print("drawing", "history.size()=\(self.de.history.count), id=\(selectedComponent!.id!)")
                        }
                        
                        self.de.clearUndoArray()

                        /*if self.de.currentMode == Mode.SELECT && self.de.drawingView!.isSelected  {
                            self.de.setPreAndPostSelectedComponentsImage()

                            self.de.clearMyCurrentImage()
                            self.de.drawUnselectedComponents()
                            self.de.selectedComponent!.drawComponent(view: self.de.drawingVC!.myCurrentView, drawingEditor: self.de)
                            self.de.drawSelectedComponentBorder(component: selectedComponent!, color: self.de.mySelectedBorderColor.cgColor)
                        }*/
                        
                        print("other selected finish")
                        break
                        
                    case .none:
                        break
                    case .some(_):
                        break
                    }
                }
            }
        }
    }
    
    
    
    func text(message: MqttMessageFormat) -> Void {
        if self.de.myUsername == message.username { return }
        
        let textMode: TextMode = message.textMode!
        let textAttr: TextAttribute = message.textAttr!
        
        var text: Text? = nil
        
        // 텍스트 객체가 처음 생성되는 경우, 텍스트 배열에 저장된 정보 없음
        // 그 이후에 일어나는 텍스트에 대한 모든 행위들은 텏트ㅡ 배열로부터 텍스트 객체를 찾아서 작업 가능
        if !(textMode == .CREATE) {
            text = de.findTextById(id: textAttr.id!)
            if text == nil { return }
            text!.textAttribute = textAttr
        }
        
        switch textMode {
        case .CREATE:
            print("*** text create")
            let newText = Text()
            newText.create(textAttribute: textAttr, drawingVC: drawingVC) // setting gesture
            de.texts.append(newText)
            
            de.drawingVC?.drawingContainer.addSubview(newText)
            newText.setNotMovedLabelLocation()
            break
        case .MODIFY_START:
            text!.setLabelBorder(color: .lightGray)
            break
        case .START_COLOR_CHANGE:
            text!.setLabelBorder(color: .gray)
            break
        case .FINISH_COLOR_CHANGE:
            text!.setMovedLabelLocation()
            text!.setLabelAttribute()
            text!.setLabelBorder(color: .clear)
            break
        case .DRAG_STARTED:
            text!.setLabelBorder(color: .lightGray)
            break
        case .DRAG_LOCATION:
            text!.setLabelLocation()
            break
        case .DRAG_EXITED:
            text!.setLabelLocation()
            break
        case .DROP:
            text!.setLabelLocation()
            text!.setLabelBorder(color: .clear)
            break
        case .DONE:
            text!.setLabelAttribute()
            text!.setMovedLabelLocation()
            text!.setLabelBorder(color: .clear)
        case .DRAG_ENDED: break
        case .ERASE:
            de.removeTexts(text: text!)
            text!.removeFromSuperview()
            break
            
        }
    }
    
    func warp(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        
        if let warpingMessage = message.warpingMessage {
            drawingVC.warp(warpData: warpingMessage.getWarpData(), width: warpingMessage.width, height: warpingMessage.height)
        }
    }
    
    func autoDraw(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        
        if let autoDrawMessage = message.autoDrawMessage {
            let SVGCoder = SDImageSVGCoder.shared
            SDImageCodersManager.shared.addCoder(SVGCoder)
            let imgView = UIImageView()
            
            var width = self.drawingVC.drawingView.bounds.size.width
            var height = self.drawingVC.drawingView.bounds.size.height
            var x = Int(autoDrawMessage.x) * Int(width) / Int(autoDrawMessage.width)
            var y = Int(autoDrawMessage.y) * Int(height) / Int(autoDrawMessage.height)
            imgView.frame = CGRect(x: x, y: y, width: 100, height: 100)
            imgView.sd_setImage(with: URL(string: autoDrawMessage.url))
            drawingVC.drawingContainer.addSubview(imgView)
            var autoDraw = AutoDraw(width: Float(width), height: Float(height), point: Point(x: x, y: y), url: autoDrawMessage.url)
            self.de.addAutoDraw(autoDraw: autoDraw)
            
        }
    }
    
    func mid(message: MqttMessageFormat) {
        DispatchQueue.global(qos: .background).async {
            //if self.de.backgroundImage == nil { return }
            
            DispatchQueue.main.async {
                //WarpingControlView imageView = new WarpingControlView(client.getDrawingFragment().getContext());
                //imageView.setLayoutParams(new LinearLayout.LayoutParams(client.getDrawingFragment().getSize().x, ViewGroup.LayoutParams.MATCH_PARENT));
                //imageView.setImage(de.getBackgroundImage());
                
                //client.getBinding().backgroundView.addView(imageView);
                
                
//                // 배경이미지 -> WarpingView
//                if let imageBytes = self.de.backgroundImage {
//                    print("mid received image")
//                    self.drawingVC.backgroundImageView.image = self.de.convertByteArray2UIImage(byteArray: imageBytes)
//                }
                
                if self.de.history.count > 0 {
                    self.drawingVC?.setUndoEnabled(isEnabled: true)
                }
                if self.de.undoArray.count > 0 {
                    self.drawingVC?.setRedoEnabled(isEnabled: true)
                }
                
                self.de.drawAllDrawingComponentsForMid()
                
                //self.de.lastDrawingImage = self.drawingVC.drawingView.image
                
                self.de.addAllTextLabelToDrawingContainer()
                
                self.de.drawingView!.setNeedsDisplay()
                
                if self.de.autoDrawList.count > 0 {
                    for i in 0 ... self.de.autoDrawList.count - 1 {
                        var autoDraw = self.de.autoDrawList[i]
                        let SVGCoder = SDImageSVGCoder.shared
                        SDImageCodersManager.shared.addCoder(SVGCoder)
                        let imgView = UIImageView()
                        
                        var width = self.drawingVC.drawingView.bounds.size.width ?? 0
                        var height = self.drawingVC.drawingView.bounds.size.height ?? 0
                        var x = autoDraw.point.x * Int(width) / Int(autoDraw.width)
                        var y = autoDraw.point.y * Int(height) / Int(autoDraw.height)
                        imgView.frame = CGRect(x: x, y: y, width: 100, height: 100)
                        imgView.sd_setImage(with: URL(string: autoDraw.url))
                        self.drawingVC?.drawingContainer?.addSubview(imgView)
                    }
                }
                
                print("mid progressdialog dismiss")
                SVProgressHUD.dismiss()
            }
            
        }
    }
    
    func clear(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode))")
        
        DispatchQueue.main.async {
            self.de.clearDrawingComponents()
            if self.de.drawingView!.isSelected { self.de.deselect(updateImage: true) }
            self.de.clearTexts()
            self.drawingVC.setRedoEnabled(isEnabled: false)
            self.drawingVC.setUndoEnabled(isEnabled: false)
        }
    }
    
    func clearBackgroundImage(message: MqttMessageFormat) {
        de.backgroundImage = nil
        de.clearBackgroundImage()
    }
    
    func undo(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode))")
        
        DispatchQueue.main.async {
            if self.de.drawingView!.isSelected { self.de.deselect(updateImage: true) }
            self.de.undo()
        }
    }
    
    func redo(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode))")
        
        DispatchQueue.main.async {
            if self.de.drawingView!.isSelected { self.de.deselect(updateImage: true) }
            self.de.redo()
        }
    }
}
