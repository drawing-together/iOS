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
    //selectCommand
    var isIntercept = false
    
    var dComponent: DrawingComponent?
    var stroke = Stroke()
    var rect = Rect()
    var oval = Oval()
    
    let src_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    let dst_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    var src: [Int32] = [], dst: [Int32] = []
    
    /*func drawComponent(component: DrawingComponent) {
        
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        self.image?.draw(in: self.bounds)
        
//      context.setBlendMode(.normal)
//      context.setBlendMode(.clear)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(component.strokeWidth!)
        context.setStrokeColor(de.strokeColor)  //
    
        
        if component.type == ComponentType.STROKE {
            context.move(to: CGPoint(x: component.points[0].x, y: component.points[0].y))
            for i in 1..<component.points.count {
                context.addLine(to: CGPoint(x: component.points[i].x, y: component.points[i].y))
            }
        }
        
        context.strokePath()
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }*/
    
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
    
    func setComponentAttribute(dComponent: DrawingComponent) {
        dComponent.username = de.username
        dComponent.usersComponentId = de.usersComponentIdCounter()
        dComponent.type = de.currentType
        //dComponent.setFillColor = de.FillColor
        dComponent.strokeColor = de.strokeColor
        dComponent.strokeAlpha = de.strokeAlpha
        dComponent.fillAlpha = de.fillAlpha
        dComponent.strokeWidth = de.strokeWidth
        dComponent.drawnCanvasWidth = de.myCanvasWidth
        dComponent.drawnCanvasHeight = de.myCanvasHeight
        dComponent.calculateRatio(myCanvasWidth: de.myCanvasWidth!, myCanvasHeight: de.myCanvasHeight!)  //화면 비율 계산
        //dComponent.isSelected = false
    }
    
    func addPoint(component: DrawingComponent, point: Point) {
        component.preSize = component.points.count
        component.addPoint(point)
        component.beginPoint = component.points[0]
        component.endPoint = point
    }
    
    func addPointAndDraw(component: DrawingComponent, point: Point) {
        component.preSize = component.points.count
        component.addPoint(point)
        component.beginPoint = component.points[0]
        component.endPoint = point
        component.draw(drawingView: self)
        if component.type == ComponentType.STROKE {
            de.lastDrawingImage = self.image
        }
        //print("drawingview width=\(Int(de.myCanvasWidth!)), height=\(Int(de.myCanvasHeight!))")
    }
    
    func doInDrawActionUp(component: DrawingComponent, canvasWidth: CGFloat, canvasHeight: CGFloat) {

        //de.removeCurrentShapes(dComponent.getUsersComponentId());
        de.splitPoints(component: component, canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        de.addDrawingComponents(component: component)
        de.addHistory(item: DrawingItem(mode: de.currentMode!, component: parser.getDrawingComponentAdapter(component: component))) // 드로잉 컴포넌트가 생성되면 History 에 저장
        //print("history.size()=\(de.history.count), id=\(String(describing: dComponent!.id))")

        de.removeCurrentComponents(usersComponentId: component.usersComponentId!)

        if de.history.count == 1 {
            //de.drawingVC.undoBtn.setEnabled(true)
        }
        de.clearUndoArray()

        //if(de.isIntercept()) this.isIntercept = true;   //**

        //de.setDrawingShape(false);

        de.printDrawingComponentArray(name: "cc", array:de.currentComponents, status: "up")
        de.printDrawingComponentArray(name: "dc", array:de.drawingComponents, status: "up")
    }
    
    func redrawShape(component: DrawingComponent) {
        if component.type != ComponentType.STROKE  { // 도형이 그려졌다면 lastDrawingBitmap 에 drawingBitmap 내용 복사
            
            //de.lastDrawingView!.image = self.image
            //de.lastDrawingView?.setNeedsDisplay()
            
            //self.image = nil
            //self.setNeedsDisplay()
            
            de.lastDrawingImage = self.image
        }
    }
    
    func redraw(usersComponentId: String) {
        if de.lastDrawingImage == nil  {
            self.image = nil
            self.setNeedsDisplay()
            return
        }

        self.image = de.lastDrawingImage
        //de.drawingVC?.selectedView.image = UIImage()
        self.setNeedsDisplay()
    }
    
    func doErase(point: Point) {
        dTool.command = eraserCommand
        dTool.doCommand(selectedPoint: point)
    }
    
    func doWarp() {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        switch de.currentMode {
        case .DRAW:
            for touch in touches {
                setEditorAttribute()
                initDrawingComponent()
                setDrawingComponentType()
                setComponentAttribute(dComponent: dComponent!)
                
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                
                self.addPointAndDraw(component: dComponent!, point: point)
                
                let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, component: parser.getDrawingComponentAdapter(component: dComponent!), action: MotionEvent.ACTION_DOWN.rawValue)
                //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
                sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
            }
            break
            
        case .ERASE:
            for touch in touches {
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                doErase(point: point)
            }
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
        //print(#function)
        switch de.currentMode {
        case .DRAW:
            for touch in touches {
                setEditorAttribute()
                setDrawingComponentType()
                
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                
                self.addPointAndDraw(component: dComponent!, point: point)
                
                points.append(point)
                if points.count == msgChunkSize {
                    let messageFormat = MqttMessageFormat(username: de.myUsername!, usersComponentId: dComponent!.usersComponentId!, mode: de.currentMode!, type: de.currentType!, movePoints: points, action: MotionEvent.ACTION_MOVE.rawValue)
                    //client.publish(topic: topicData!, message: parser.jsonWrite(object: messageFormat)!)
                    sendMqttMessage.putMqttMessage(messageFormat: messageFormat)
                    points.removeAll()
                }
                
            }
            break
            
        case .ERASE:
            for touch in touches {
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                doErase(point: point)
            }
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
        switch de.currentMode {
        case .DRAW:
            for touch in touches {
                setEditorAttribute()
                setDrawingComponentType()
                
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                
                self.addPointAndDraw(component: dComponent!, point: point)
                de.lastDrawingImage = self.image
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
            }
            break
            
        case .ERASE:
            break
        
        case .none:
            break
        case .some:
            break
            
        }
    }
    
    func clear() {
        de.drawingVC!.eraserVC.dismiss(animated: true, completion: nil)
        
        let alertController = UIAlertController(title: "화면 초기화", message: "모든 그리기 내용이 삭제됩니다.\n그래도 지우시겠습니까?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "YES", style: .destructive) {
            (action) in
            
            //        de.initSelectedBitmap();
            //
            //        sendModeMqttMessage(Mode.CLEAR); *****
            //        de.clearDrawingComponents();
            //        de.clearTexts();
            //        de.getDrawingFragment().getBinding().redoBtn.setEnabled(false);
            //        de.getDrawingFragment().getBinding().undoBtn.setEnabled(false);
            //        invalidate();
            self.sendModeMqttMessage(mode: Mode.CLEAR)
        }
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        
        de.drawingVC?.present(alertController, animated: true)
    }
    
    func clearBackgroundImage() {
        de.drawingVC!.eraserVC.dismiss(animated: true, completion: nil)
        
        let alertController = UIAlertController(title: "배경 초기화", message: "배경 이미지가 삭제됩니다.\n그래도 지우시겠습니까?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "YES", style: .destructive) {
            (action) in
            
            self.sendModeMqttMessage(mode: Mode.CLEAR_BACKGROUND_IMAGE)
            self.de.backgroundImage = nil
            self.de.clearBackgroundImage()
        }
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        
        de.drawingVC?.present(alertController, animated: true)
    }
}
