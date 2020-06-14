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
    
    //sendMqttMessage
    //msgChunkSize
    //points
    var topicData: String?  //
    
    //dTool
    //eraserCommand
    //selectCommand
    var isIntercept = false
    
    var dComponent: DrawingComponent?
    var stroke = Stroke()
    var rect = Rect()
    
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
            //dComponent = oval
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
            //oval = Oval()
            break
        case .none:
            break
        }
    }
    
    func setComponentAttribute(dComponent: DrawingComponent) {
        dComponent.username = de.username
        dComponent.usersComponentId = de.usersComponentIdCounter()
        dComponent.type = de.currentType
        //dComponent.setFillColor = de.FillColor
        dComponent.strokeColor = de.strokeColor
        //dComponent.strokeAlpha = de.strokeAlpha
        //dComponent.fillAlpha = de.fillAlpha
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
        print("drawingview width=\(Int(de.myCanvasWidth!)), height=\(Int(de.myCanvasHeight!))")
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

        de.printCurrentComponents(status: "up")
        de.printDrawingComponents(status: "up")
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        switch de.currentMode {
        case .DRAW:
            for touch in touches {
                setEditorAttribute()
                setDrawingComponentType()
                
                let location = touch.location(in: self)
                let point = Point(x: Int(location.x), y: Int(location.y))
                
                self.addPointAndDraw(component: dComponent!, point: point)
                
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
    
}
