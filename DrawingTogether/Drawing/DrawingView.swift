//
//  DrawingView.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/03.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import UIKit

class DrawingView: UIImageView {
    var de = DrawingEditor.INSTANCE
    var client = MQTTClient.client
    var parser = JSONParser.parser
    var sendMqttMessage = SendMqttMessage.INSTANCE
    
    //sendMqttMessage
    var msgChunkSize = 20
    var points = [Point]()
    var topicData: String?  //
    
    var dTool: DrawingTool = DrawingTool()
    var eraserCommand: Command = EraseCommand()
    var selectCommand: Command = SelectCommand()
    var isExit = false
    var isIntercept = false
    var isMovable = false
    
    var isSelected = false
    var selectMsgChunkSize = 10
    var selectDownPoint: Point?
    var selectPrePoint: Point?
    var selectPostPoint: Point?
    var moveX: Int = 0
    var moveY: Int = 0
    var moveSelectPoints = [Point]()
    
    var dComponent: DrawingComponent?
    var stroke = Stroke()
    var rect = Rect()
    var oval = Oval()
    
    let src_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    let dst_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    var src: [Int32] = [], dst: [Int32] = []
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        if !de.isIntercept { self.isIntercept = false }
        if self.isIntercept || de.isIntercept {
            print("intercept drawing view touch")
            return
        }
        
        switch de.currentMode {
        case .DRAW:
            drawTouchesBegan(touches, with: event)
            break
        case .ERASE:
            eraseTouchesBegan(touches, with: event)
            break
        case .SELECT:
            selectTouchBegan(touches, with: event)
            break
        case .WARP:
            super.touchesBegan(touches, with: event)
            break
            
        case .none:
            break
        case .some:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !de.isIntercept { self.isIntercept = false }
        if self.isIntercept {
            print("intercept drawing view touch")
            return
        }
        
        //print(#function)
        switch de.currentMode {
        case .DRAW:
            if !isMovable {
                print("intercept drawing view touch 222")
                return
            }
            drawTouchesMoved(touches, with: event)
            break
        case .ERASE:
            eraseTouchesBegan(touches, with: event)
            break
        case .SELECT:
            selectTouchMoved(touches, with: event)
            break
        case .WARP:
            super.touchesMoved(touches, with: event)
            break
            
        case .none:
            break
        case .some:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        if !de.isIntercept { self.isIntercept = false }
        if self.isIntercept {
            print("intercept drawing view touch")
            return
        }

        switch de.currentMode {
        case .DRAW:
            if !isMovable {
                print("intercept drawing view touch 222")
                return
            }
            drawTouchesEnded(touches, with: event)
            break
        case .SELECT:
            selectTouchEnded(touches, with: event)
            break
            
        case .none:
            break
        case .some:
            break
        }
    }
    
    func setEditorAttribute() {
        topicData = client.topic_data
        
        de.username = de.myUsername
        de.drawnCanvasWidth = self.bounds.size.width
        de.drawnCanvasHeight = self.bounds.size.width
        de.myCanvasWidth = self.bounds.size.width
        de.myCanvasHeight = self.bounds.size.height
    }
    
    func setDrawingComponentType() {
        switch de.currentType {
        case .STROKE:
            dComponent = stroke
            break
        case .RECT:
            dComponent = rect
            break
        case .OVAL:
            dComponent = oval
            break
        case .none:
            break
        }
    }
    
    func initDrawingComponent() {
        switch de.currentType {
        case .STROKE:
            stroke = Stroke()
            break
        case .RECT:
            rect = Rect()
            break
        case .OVAL:
            oval = Oval()
            break
        case .none:
            break
        }
    }
    
    func sendModeMqttMessage(mode: Mode) {
        let messageFormat = MqttMessageFormat(username: de.myUsername!, mode: mode);
        sendMqttMessage.putMqttMessage(messageFormat: messageFormat);
    }
    
    func sendSelectMqttMessage(isSelected: Bool) {
        if let comp = de.selectedComponent {
            let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: comp.usersComponentId!, mode: Mode.SELECT, isSelected: isSelected)
            sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
        }
    }
    
    func setComponentAttribute(dComponent: DrawingComponent) {
        dComponent.username = de.username
        dComponent.usersComponentId = de.usersComponentIdCounter()
        dComponent.type = de.currentType
        dComponent.penMode = de.penMode
        dComponent.strokeColor = de.strokeColor
        dComponent.strokeAlpha = de.strokeAlpha
        dComponent.fillColor = de.strokeColor   //todo
        dComponent.fillAlpha = de.fillAlpha
        dComponent.strokeWidth = de.strokeWidth
        dComponent.drawnCanvasWidth = de.myCanvasWidth
        dComponent.drawnCanvasHeight = de.myCanvasHeight
        dComponent.calculateRatio(myCanvasWidth: de.myCanvasWidth!, myCanvasHeight: de.myCanvasHeight!)  //화면 비율 계산
        //dComponent.isSelected = false
    }
    
    func addPoint(component: DrawingComponent, point: Point) {
        component.addPoint(point)
        component.beginPoint = component.points[0]
        component.endPoint = point
    }
    
    func addPointAndDraw(component: DrawingComponent, point: Point, view: UIImageView) {
        component.addPoint(point)
        component.beginPoint = component.points[0]
        component.endPoint = point
        component.draw(view: view, drawingEditor: de)
        
        //print("drawingview width=\(Int(de.myCanvasWidth!)), height=\(Int(de.myCanvasHeight!))")
    }
    
    func doInDrawActionUp(component: DrawingComponent, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        de.splitPoints(component: component, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        de.addDrawingComponents(component: component)
        
        if let copyComponent = component.clone() {
            de.addHistory(item: DrawingItem(mode: Mode.DRAW, component: parser.getDrawingComponentAdapter(component: copyComponent))) // 드로잉 컴포넌트가 생성되면 History 에 저장
            print("history.size()=\(de.history.count), id=\(String(describing: component.id))")
        }
            
        de.removeCurrentComponents(usersComponentId: component.usersComponentId!)
        
        if de.history.count == 1 {
            de.drawingVC?.setUndoEnabled(isEnabled: true)
        }
        de.clearUndoArray()
        
        //if(de.isIntercept()) this.isIntercept = true;   //**
        
        
        de.printDrawingComponentArray(name: "cc", array:de.currentComponents, status: "up")
        de.printDrawingComponentArray(name: "dc", array:de.drawingComponents, status: "up")
    }
    
    func doErase(point: Point) {
        dTool.command = eraserCommand
        dTool.doCommand(selectedPoint: point)
    }
    
    func doWarp() {
        
    }
    
    
    func doInMyDrawActionUP(point: Point) {
        self.addPointAndDraw(component: dComponent!, point: point, view: de.drawingVC!.myCurrentView)
        
        dComponent?.drawComponent(view: self, drawingEditor: de)
        de.drawingVC?.myCurrentView.image = nil
        
        //de.lastDrawingImage = self.image
        //redrawShape(component: dComponent!)
        
        if(points.count != 0) {
            let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, movePoints: points, action: MotionEvent.ACTION_MOVE.rawValue)
            //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
            sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
            points.removeAll()
        }
        
        let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, point: point, action: MotionEvent.ACTION_UP.rawValue)
        //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
        sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
        
        if de.isIntercept {
            self.isIntercept = true
            print("drawingView intercept true")
        }
        
        isMovable = false
    }
    
    func drawTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            //print("view w=\(self.bounds.size.width), h=\(self.bounds.size.height) | image w=\(self.image!.size.width), h=\(self.image!.size.height)")
            
            isExit = false
            print("isExit false")
            
            setEditorAttribute()
            initDrawingComponent()
            setDrawingComponentType()
            setComponentAttribute(dComponent: dComponent!)
            
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            //self.addPointAndDraw(component: dComponent!, point: point)
            
            let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, component: parser.getDrawingComponentAdapter(component: dComponent!), action: MotionEvent.ACTION_DOWN.rawValue)
            //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
            sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
            
            isMovable = true
        }
    }
    
    func drawTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if isExit {
                print("drawing exit 1")
                return
            }
            
            setEditorAttribute()
            setDrawingComponentType()
            
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            
            //터치가 DrawingView 밖으로 나갔을 때
            if (Int(location.x)-5 < 0) || (Int(location.y)-5 < 0) || (Int(de.myCanvasWidth!)-5 < Int(location.x)) || (Int(de.myCanvasHeight!)-5 < Int(location.y)) {
                print("drawing exit 2")
                
                if dComponent?.points.count == 0 { return }
                
                doInMyDrawActionUP(point: dComponent!.endPoint!)
                isExit = true
                return
            }
            
            self.addPointAndDraw(component: dComponent!, point: point, view: de.drawingVC!.myCurrentView)
            
            points.append(point)
            if points.count == msgChunkSize {
                print("send move chunk")
                let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, movePoints: points, action: MotionEvent.ACTION_MOVE.rawValue)
                //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
                sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
                points.removeAll()
            }
            
            isMovable = true
        }
    }
    
    func drawTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if isExit {
                print("drawing exit 1")
                return
            }
            
            setEditorAttribute()
            setDrawingComponentType()
            
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            
            doInMyDrawActionUP(point: point)
        }
    }
    
    func eraseTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            doErase(point: point)
        }
    }
    
    var totalMoveX = 0
    var totalMoveY = 0
    var preMoveX = 0
    var preMoveY = 0
    func selectTappedEnded(point: Point) {
        
        //if !isSelected {
        
        dTool.command = selectCommand
        dTool.doCommand(selectedPoint: point)
        
        if let ids = dTool.getIds(), ids.count > 0, ids[0] != -1, selectMoveCount < 8 {
            let selectedComponentId = ids[0]
            
            if let component = de.findDrawingComponentById(id: selectedComponentId), let usersComponentId = component.usersComponentId {
                
                /*if component.isSelected {
                 component.isSelected = false
                 de.setDrawingComponentSelected(usersComponentId, isSelected: false)
                 
                 //todo publish - 다른 사람들 셀렉트 가능 --> 모드 바뀔 때 추가로 메시지 전송 필요
                 sendSelectMqttMessage(isSelected: false);
                 }*/
                if !component.isSelected {
                    isSelected = true
                    
                    de.selectedComponent = component
                    component.isSelected = true
                    de.setDrawingComponentSelected(usersComponentId, isSelected: true)
                    
                    de.setPreSelectedComponents(id: selectedComponentId)
                    de.setPostSelectedComponents(id: selectedComponentId)
                    
                    //de.setPreAndPostSelectedComponentsImage()
                    
                    de.drawSelectedComponentBorder(component: component, color: de.mySelectedBorderColor.cgColor)
                    
                    
                    //de.drawingVC?.myCurrentView?.setNeedsDisplay()
                    
                    //select success
                    print("selected id=\(selectedComponentId)")
                    
                    //todo publish - 다른 사람들 셀렉트 못하게
                    sendSelectMqttMessage(isSelected: true)
                    
                } else {
                    print("already selected")
                    de.drawingVC?.showToast(message: "다른 사람이 선택한 도형입니다")
                }
                
            }
        }
        
        selectMoveCount = 0
        //}
    }
    
    func selectTouchBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            
            if !isSelected {
                selectPrePoint = point
                return
            }
            
            print("selected down")
            
            selectDownPoint = point
            if !de.isContainsSelectedComponent(point: selectDownPoint!) {
                isSelected = false
                if let component = de.selectedComponent, let usersComponentId = component.usersComponentId {
                    component.isSelected = false
                    print("selected false")
                    //de.initSelectedBitmap();
                    //de.deselect();
                    
                    de.setDrawingComponentSelected(usersComponentId, isSelected: false)
                    de.clearMyCurrentImage()
                    
                    //todo publish - 다른 사람들 셀렉트 가능
                    sendSelectMqttMessage(isSelected: false)
                }
                return
            }
            
            if let component = de.selectedComponent, let usersComponentId = component.usersComponentId {
                de.clearMyCurrentImage()
                
                de.setPreAndPostSelectedComponentsImage()
                de.drawUnselectedComponents()
                component.drawComponent(view: de.drawingVC!.myCurrentView, drawingEditor: de)
                de.drawSelectedComponentBorder(component: component, color: de.mySelectedBorderColor.cgColor)
                
                print("selected true")
                
                totalMoveX = 0
                totalMoveY = 0
                preMoveX = component.beginPoint!.x
                preMoveY = component.beginPoint!.y
                //todo publish - selected down
                moveSelectPoints.removeAll()
                
                let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: usersComponentId, mode: Mode.SELECT, action: MotionEvent.ACTION_DOWN.rawValue, moveSelectPoints: moveSelectPoints)
                sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
            }
            
            return
        }
    }
    
    var selectMoveCount = 0
    func selectTouchMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            
            if !isSelected {
                selectPostPoint = point
                if selectPrePoint === selectPostPoint {
                    selectMoveCount += 1
                    selectPrePoint = selectPostPoint
                }
                return
            }
            
            print("selected move")
            
            if let component = de.selectedComponent, let usersComponentId = component.usersComponentId {
                
                moveX = Int(CGFloat(point.x - selectDownPoint!.x)/component.xRatio)
                moveY = Int(CGFloat(point.y - selectDownPoint!.y)/component.yRatio)
                
                let datumPoint = Point(x: Int(CGFloat(component.datumPoint!.x) * (component.xRatio)), y: Int(CGFloat(component.datumPoint!.y) * (component.yRatio)))
                let width = component.width
                let height = component.height
                
                let rH = datumPoint.y + moveY + height! + 10
                let rW = datumPoint.x + moveX + width! + 10
                
                if ((datumPoint.x+moveX-10 < 0) && (moveX < 0)) || ((datumPoint.y+moveY-10 < 0) && (moveY < 0)) {
                    return
                }
                
                if (rH > Int(de.myCanvasHeight!) && moveY > 0) || (rW > Int(de.myCanvasWidth!) && moveX > 0) {
                    return
                }
                
                totalMoveX += moveX
                totalMoveY += moveY
                
                selectDownPoint = point
                
                de.clearMyCurrentImage()
                de.moveSelectedComponent(selectedComponent: component, moveX: moveX, moveY: moveY)
                component.drawComponent(view: de.drawingVC!.myCurrentView, drawingEditor: de)
                de.drawSelectedComponentBorder(component: component, color: de.mySelectedBorderColor.cgColor)
                
                //todo publish - selected move
                moveSelectPoints.append(Point(x: moveX, y: moveY))
                
                if moveSelectPoints.count == selectMsgChunkSize {
                    print("send selected move chunk")
                    
                    let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: usersComponentId, mode: Mode.SELECT, action: MotionEvent.ACTION_MOVE.rawValue, moveSelectPoints: moveSelectPoints)
                    
                    sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
                    moveSelectPoints.removeAll()
                }
            }
            
            return
        }
    }
    
    func selectTouchEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let location = touch.location(in: self)
            let point = Point(x: Int(location.x), y: Int(location.y))
            
            if !isSelected {
                selectTappedEnded(point: point)
                return
            }
            
            print("selected up")
            
            if let component = de.selectedComponent, let usersComponentId = component.usersComponentId {
                de.clearMyCurrentImage()
                de.updateDrawingImage(border: true)
                de.splitPointsOfSelectedComponent(component: component, canvasWidth: de.myCanvasWidth!, canvasHeight: de.myCanvasHeight!)
                de.updateSelectedComponent(newComponent: component)
                print("drawingComponents.size() = \(de.drawingComponents.count)")
                
                if let copyComponent = component.clone() {
                    de.addHistory(item: DrawingItem(mode: Mode.SELECT, component: parser.getDrawingComponentAdapter(component: copyComponent), movePoint: Point(x: totalMoveX, y: totalMoveY)))
                    print("drawing", "history.size()=\(de.history.count), preBeginPoint=(\(preMoveX),\(preMoveY)), postBeginPoint-movePoint=(\(component.beginPoint!.x - totalMoveX),\(component.beginPoint!.y - totalMoveY)), postBeginPoint=(\(component.beginPoint!.x),\(component.beginPoint!.y))")
                }
                    
                de.clearUndoArray()
                
                //todo publish - selected up
                if moveSelectPoints.count != 0 {
                    print("send selected move chunk")
                    
                    sendMqttMessage.putMqttMessage(messageFormat: MqttMessageFormat(username: de.myUsername!, usersComponentId: usersComponentId, mode: Mode.SELECT, action: MotionEvent.ACTION_MOVE.rawValue, moveSelectPoints: moveSelectPoints))
                    moveSelectPoints.removeAll()
                }
                sendMqttMessage.putMqttMessage(messageFormat: MqttMessageFormat(username: de.myUsername!, usersComponentId: usersComponentId, mode: Mode.SELECT, action: MotionEvent.ACTION_UP.rawValue, moveSelectPoints: moveSelectPoints))
            }
            
            return
        }
    }
    
    func clear() {
        de.drawingVC!.eraserVC.dismiss(animated: true, completion: nil)
        
        let alertController = UIAlertController(title: "배경 초기화", message: "배경 이미지가 삭제됩니다.\n그래도 지우시겠습니까?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "확인", style: .destructive) {
            (action) in
            
            self.de.initSelectedImage()
            
            self.sendModeMqttMessage(mode: Mode.CLEAR)
            self.de.clearDrawingComponents()
            //self.de.clearTexts()
            
            self.setNeedsDisplay()
            
            self.de.drawingVC?.setRedoEnabled(isEnabled: false)
            self.de.drawingVC?.setUndoEnabled(isEnabled: false)
            
            self.sendModeMqttMessage(mode: Mode.CLEAR_BACKGROUND_IMAGE)
            self.de.backgroundImage = nil
            self.de.clearBackgroundImage()
        }
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        de.drawingVC?.present(alertController, animated: true)
    }
    
    func clearBackgroundImage() {
        de.drawingVC!.eraserVC.dismiss(animated: true, completion: nil)
        
        let alertController = UIAlertController(title: "배경 초기화", message: "배경 이미지가 삭제됩니다.\n그래도 지우시겠습니까?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "확인", style: .destructive) {
            (action) in
            
            self.sendModeMqttMessage(mode: Mode.CLEAR_BACKGROUND_IMAGE)
            self.de.backgroundImage = nil
            self.de.clearBackgroundImage()
        }
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        de.drawingVC?.present(alertController, animated: true)
    }
    
    func clearDrawingView() {
        de.drawingVC!.eraserVC.dismiss(animated: true, completion: nil)
        
        let alertController = UIAlertController(title: "화면 초기화", message: "모든 그리기 내용이 삭제됩니다.\n그래도 지우시겠습니까?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "확인", style: .destructive) {
            (action) in
            
            self.de.initSelectedImage()
            
            self.sendModeMqttMessage(mode: Mode.CLEAR)
            self.de.clearDrawingComponents()
            //self.de.clearTexts()
            
            self.setNeedsDisplay()
            
            self.de.drawingVC?.setRedoEnabled(isEnabled: false)
            self.de.drawingVC?.setUndoEnabled(isEnabled: false)
        }
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        de.drawingVC?.present(alertController, animated: true)
    }
    
    func undo() {
        de.initSelectedImage()
        sendModeMqttMessage(mode: Mode.UNDO)
        de.undo()
        
        //if de.undoArray.count == 1 { self.de.drawingVC?.setRedoEnabled(isEnabled: true) }
        //if de.history.count == 0 { self.de.drawingVC?.setUndoEnabled(isEnabled: false) }
        
        self.setNeedsDisplay()
    }
    
    func redo() {
        de.initSelectedImage()
        sendModeMqttMessage(mode: Mode.REDO)
        de.redo()
        
        //if de.history.count == 1 { self.de.drawingVC?.setUndoEnabled(isEnabled: true) }
        //if de.undoArray.count == 0 { self.de.drawingVC?.setRedoEnabled(isEnabled: false) }
        
        self.setNeedsDisplay()
    }
}
