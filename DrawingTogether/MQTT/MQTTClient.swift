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
    var topic_alive: String!
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
    
    // AUDIO
    private var audioPlaying: Bool = false
    
    // ALIVE
    private var aliveThread: AliveThread!
    private var aliveLimitCount: Int!
    
    // OBSERVE
    var observeThread: ObserveThread!
    
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
        self.topic_alive = topic + "_alive"
        
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

                self.observeThread = ObserveThread()
                self.observeThread.start()

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
        //        print("pub: \(topic) \(message)")
    }
    
    public func subscribeAllTopics() {
        subscribe(topic_join)
        subscribe(topic_exit)
        subscribe(topic_close)
        subscribe(topic_data)
        subscribe(topic_mid)
        subscribe(topic_alive)
    }
    
    public func unsubscribeAllTopics() {
        unsubscribe(topic_join)
        unsubscribe(topic_exit)
        unsubscribe(topic_close)
        unsubscribe(topic_data)
        unsubscribe(topic_mid)
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
        observeThread.cancel()
        de.removeAllDrawingData()
        isMid = true
        
        // 오디오 처리 - 수정 필요
        if drawingVC.speakerFlag {
            unsubscribe(topic_audio)
            audioPlaying = false
        }
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
    
    // GETTER
    public func getTopic() -> String { return self.topic }
    
    public func getMyName() -> String { return self.myName }
    
}

extension MQTTClient: MQTTSessionManagerDelegate, MQTTSessionDelegate {
    // callback
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        let message = String(data: data, encoding: .utf8)!
        //        print("Message \(message)")
        
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
                                               
                        if de.currentMode == Mode.DRAW {
                            de.isIntercept = true
                        }
                                               
                        drawingVC.showToast(message: "[ \(joinName) ] 님이 접속하셨습니다")
                        setUserNumAndNames()
                        
                    }
                    if master {
                         if isUsersActionUp(username: joinName) /*&& isTextInUse()*/ { // fixme nayeon
                            
                            let joinAckMsg = JoinAckMessage(name: myName, target: joinName)
                            var messageFormat: MqttMessageFormat?
                            
                            // 배경 이미지가 없는 경우
                            if de.backgroundImage == nil {
                                messageFormat = MqttMessageFormat(joinAckMessage: joinAckMsg, drawingComponents: parser.getDrawingComponentAdapters(components: de.drawingComponents), texts: parser.getTextAdapters(texts: de.texts), history: de.history, undoArray: de.undoArray, removedComponentId: de.removedComponentId, maxComponentId: de.maxComponentId, maxTextId: de.maxTextId);
                                
                            }
                            // 배경 이미지가 있는 경우
                            else {
                                messageFormat = MqttMessageFormat(joinAckMessage: joinAckMsg, drawingComponents: parser.getDrawingComponentAdapters(components: de.drawingComponents), texts: parser.getTextAdapters(texts: de.texts), history: de.history, undoArray: de.undoArray, removedComponentId: de.removedComponentId, maxComponentId: de.maxComponentId, maxTextId: de.maxTextId, bitmapByteArray: de.bitmapByteArray!);
                            }
                            
                            let json = parser.jsonWrite(object: messageFormat!);
                            MQTTClient.client2.publish(topic: topic_join, message: json!)
                            print("login data publish complete -> \(joinName)")
                            
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
                         
                         // 배경 이미지 세팅
                         if mqttMessageFormat.bitmapByteArray != nil {
                             print("bitmap byte array")
                             de.bitmapByteArray = mqttMessageFormat.bitmapByteArray!
                         }
                         
                         MQTTClient.client2.publish(topic: topic_mid, message: parser.jsonWrite(object: MqttMessageFormat(username: myName, mode: Mode.MID))!)                    }
                    
                    else if !isContainsUserList(name: joinAckName) {
                        
                        let user = User(name: joinAckName, count: 0, action: MotionEvent.ACTION_UP.rawValue, isInitialized: false)
                        self.userList.append(user)
                        setUserNumAndNames()
                        
                    }
                }
            }
        }
        
        if (topic == topic_exit) {
            print("TOPIC_EXIT : \(message)")
            
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
            print("TOPIC_CLOSE : \(message)")
            
            let closeMessage = mqttMessageFormat.closeMessage
            if let closeName = closeMessage?.name, closeName != myName {
                drawingVC.userVC.dismiss(animated: true, completion: nil)
                self.drawingVC.showAlert(title: "회의 종료", message: "master가 회의를 종료하였습니다.", selectable: false)
            }
        }
        
        if (topic == topic_data) {
            //print("TOPIC_DATA : \(message)")
            
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
            case .BACKGROUND_IMAGE:
                background(message: mqttMessageFormat)
                break
                /*case .SELECT:
                 self.select(message: mqttMessageFormat)
                 break*/
            case .WARP:
                self.warp(message: mqttMessageFormat)
                break
            case .some(_):
                break
            case .none:
                break
            }
            
        }
        
        if (topic == topic_mid) {
            print("TOPIC_MID : \(message)")
            
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
        
        DispatchQueue.global(qos: .background).async {
            print("action=\(String(describing: action)) This is run on the background queue")
            if let component = message.component?.getComponent() {
                dComponent = component
                
            } else {
                if let component = self.de.getCurrentComponent(usersComponentId: message.usersComponentId!) {
                    dComponent = component
                    print("component move, up")
                } else {
                    print("component nil")
                    return
                }
            }
            
            DispatchQueue.main.async {
                print("This is run on the main queue, after the previous code in outer block")
                
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
                            self.de.drawingView!.addPointAndDraw(component: dComponent!, point: point)
                        }
                    }
                    self.updateUsersAction(username: username!, action: action!)
                    break
                    
                case MotionEvent.ACTION_UP.rawValue:
                    if self.de.myUsername == username {
                        self.de.drawingView?.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                        if(self.de.isIntercept) {
                            self.de.drawingView!.isIntercept = true
                            print("drawingview intercept true")
                        }
                    } else {
                        print("up \((dComponent!.username)!), \((dComponent!.id)!)")
                        // de.drawingView.redrawShape(dComponent);
                        self.de.drawingView!.doInDrawActionUp(component: dComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!);
                        
                        self.de.lastDrawingImage = self.de.drawingView!.image
                    }
                    self.updateUsersAction(username: username!, action: action!);
                    break
                    
                case .none: break
                case .some(_): break
                    
                }
                
                self.de.drawingView!.setNeedsDisplay()
                
                //client.updateUsersAction(username, action);
                
                //if de.myUsername == username { return }
                
            }
            
        }
    }
    
    func erase(message: MqttMessageFormat) {
        DispatchQueue.global(qos: .background).async {
            if self.de.myUsername == message.username { return }
            
            DispatchQueue.main.async {
                print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode)), id=\(message.componentIds!)")
                let erasedComponentIds = message.componentIds!
                EraserTask(erasedComponentIds: erasedComponentIds).execute()
                
                self.de.clearUndoArray()
                
                //self.de.drawingView!.setNeedsDisplay()
            }
        }
    }
    
    /*func select(message: MqttMessageFormat) {
        let myCanvasWidth = self.de.myCanvasWidth
        let myCanvasHeight = self.de.myCanvasHeight
        
        DispatchQueue.global(qos: .background).async {
            if self.de.myUsername == message.username { return }
            
            if message.action == nil {
                let selectedComponent = self.de.findDrawingComponentByUsersComponentId(usersComponentId: message.usersComponentId!)
                if selectedComponent != nil {
                    selectedComponent!.isSelected = message.isSelected!
                }
            }
            
            DispatchQueue.main.async {
                
                let selectedComponent = self.de.findDrawingComponentByUsersComponentId(usersComponentId: message.usersComponentId!)
                if selectedComponent == nil { return }
                
                print("MESSAGE ARRIVED message: username=\(String(describing: message.username)), mode=\(String(describing: message.mode)), uid=\(message.usersComponentId!)")
                
                if message.action == nil {
                    if message.isSelected! {
                        self.de.clearSelectedBitmap()
                        self.de.drawSelectedComponentBorder(component: selectedComponent!, color: self.de.selectedBorderColor);
                    } else {
                        self.de.clearSelectedBitmap()
                    }
                } else {
                    switch message.action {
                    case MotionEvent.ACTION_DOWN.rawValue:
                        print("other selected true")
                        break
                    case MotionEvent.ACTION_MOVE.rawValue:
                        self.de.moveSelectedComponent(selectedComponent: selectedComponent!, moveX: message.moveX!, moveY: message.moveY!)
                        break
                    case MotionEvent.ACTION_UP.rawValue:
                        self.de.clearSelectedBitmap()
                        self.de.drawSelectedComponentBorder(component: selectedComponent!, color: self.de.selectedBorderColor)
                        self.de.updateSelectedComponent(component: selectedComponent!, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                        self.de.updateDrawingComponents(newComponent: selectedComponent!)
                        self.de.clearDrawingBitmap()
                        self.de.drawAllDrawingComponents()
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
    }*/
    
    
    
    func text(message: MqttMessageFormat) -> Void {
        if self.de.myUsername == message.username { return }
        
        let textMode: TextMode = message.textMode!
        let textAttr: TextAttribute = message.textAttr!
        
        var text: Text? = nil
        
        // 텍스트 객체가 처음 생성되는 경우, 텍스트 배열에 저장된 정보 없음
        // 그 이후에 일어나는 텍스트에 대한 모든 행위들은 텏트ㅡ 배열로부터 텍스트 객체를 찾아서 작업 가능
        if !(textMode == .CREATE) {
            print("*** check create")
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
            de.removeText(text: text!)
            text!.removeFromSuperview()
            break
            
        }
    }
    
    func background(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        
        drawingVC.backgroundImageView.image = drawingVC.convertByteArray2UIImage(byteArray: message.bitmapByteArray!)
    }
    
    func warp(message: MqttMessageFormat) {
        if self.de.myUsername == message.username { return }
        
        if let warpingMessage = message.warpingMessage {
            drawingVC.warp(warpData: warpingMessage.getWarpData())
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
                
                
                // 배경이미지 -> WarpingView
                if let imageBytes = self.de.bitmapByteArray {
                    print("mid received image")
                    self.drawingVC.backgroundImageView.image = self.drawingVC.convertByteArray2UIImage(byteArray: imageBytes)
                }
                
                if self.de.history.count > 0 {
                    //drawingCV.undoBtn.setEnabled(true)
                }
                if self.de.undoArray.count > 0 {
                    //drawingCV.redoBtn.setEnabled(true)
                }
                
                self.de.drawAllDrawingComponentsForMid()
                
                self.de.lastDrawingImage = self.drawingVC.drawingView.image
                
                self.de.addAllTextLabelToDrawingContainer()
                
                self.de.drawingView!.setNeedsDisplay()
                
                print("mid progressdialog dismiss")
                SVProgressHUD.dismiss()
            }
            
        }
    }
    
    
}
