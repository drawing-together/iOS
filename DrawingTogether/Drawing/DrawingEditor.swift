//
//  DrawingEditor.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import UIKit

class DrawingEditor {
    static let INSTANCE = DrawingEditor()
    private init() {  }
    
    var drawingView: DrawingView?
    var drawingVC: DrawingViewController?
    
    var backgroundImage: CGImage?
    
    var isIntercept: Bool?
    
    // MARK: 드로잉 컴포넌트에 필요한 객체
    var componentId: Int = -1
    var maxComponentId: Int = -1
    var drawingComponents = [DrawingComponent]()
    var currentComponents = [DrawingComponent]()
    var drawingBoardArray: [[[Int]]]?
    var drawingBoardMap = [Int : [Point]]()
    var removedComponentId = [Int]()
    
    // MARK: UNDO, REDO를 위한 객체
    var history = [DrawingItem]()
    var undoArray = [DrawingItem]()
    
    // MARK: 드로잉 컴포넌트 속성
    var currentMode: Mode?
    var currentType: ComponentType?
    var myUsername: String?
    var username: String?
    var drawnCanvasWidth: CGFloat?
    var drawnCanvasHeight: CGFloat?
    var myCanvasWidth: CGFloat?
    var myCanvasHeight: CGFloat?
    
    // MARK: 드로잉 펜 속성
    var fillColor: Int?
    var strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).rgb()
    var strokeWidth: CGFloat = 10
    
    // MARK: 텍스트에 필요한 객체
    var texts: [TextAttribute] = []
    var currentText: Text?
    var isTextBeingEditied = false
    var maxTextId = -1
    
    var isMidEntered = false
    
    // MARK: 텍스트 속성
    var textSize = UIFont.systemFont(ofSize: 20)
    var textColor = UIColor.black
    var textBackgroundColor: UIColor?
    // var fontStyle
    
    
    func initialize(drawingVC: DrawingViewController, drawingView: DrawingView) {
        self.drawingVC = drawingVC
        self.drawingView = drawingView
        currentType = ComponentType.STROKE
        currentMode = Mode.DRAW
        myCanvasWidth = drawingView.bounds.size.width
        myCanvasHeight = drawingView.bounds.size.height
        
        if(drawingBoardArray == nil) {
            print("drawingview width=\(Int(myCanvasWidth!)), height=\(Int(myCanvasHeight!))")
            initDrawingBoardArray(width: Int(myCanvasWidth!), height: Int(myCanvasHeight!))
        }
    }
    
    func removeAllDrawingData() {
        componentId = -1;
        maxComponentId = -1;
        removedComponentId.removeAll()
        clearDrawingBoardArray();
        drawingBoardMap.removeAll()
        
        drawingComponents.removeAll()
        currentComponents.removeAll()
        
        //removeAllTextViewToFrameLayout()
        texts.removeAll()
        currentText = nil
        
        history.removeAll()
        undoArray.removeAll()
        
        currentMode = Mode.DRAW
        currentType = ComponentType.STROKE
        strokeColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).rgb()
        strokeWidth = 10
        
        isIntercept = false
    }
    
    
    
    func drawAllDrawingComponents() {
        for component in drawingComponents {
            component.drawComponent(drawingView: drawingView!)
        }
    }
    
    func drawAllCurrentStrokes() {
        for component in currentComponents {
            if component.type == ComponentType.STROKE {
                component.drawComponent(drawingView: drawingView!)
            }
        }
    }
    
    func drawAllDrawingComponentsForMid() {   //drawingComponents draw
        //print("drawn width=\((drawingComponents[0].drawnCanvasWidth)!), height=\((drawingComponents[0].drawnCanvasHeight)!)")
        for component in drawingComponents {

            component.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
            component.drawComponent(drawingView: drawingView!)

            splitPoints(component: component, canvasWidth: CGFloat(drawingBoardArray![0].count), canvasHeight: CGFloat(drawingBoardArray!.count));
        }

        print("drawingBoardArray[][] w=\(drawingBoardArray![0].count), h=\(drawingBoardArray!.count)")
        print("dba[0][0] = \(drawingBoardArray![0][0][0])")
    }
    
    func componentIdCounter() -> Int {
        self.maxComponentId += 1
        return self.maxComponentId
    }
    
    func usersComponentIdCounter() -> String {
        self.componentId += 1
        let str = "\(self.username!)-\(String(self.componentId))"
        return str
    }
    
    func getCurrentComponent(usersComponentId: String) -> DrawingComponent? {
        for component in currentComponents {
            if component.usersComponentId == usersComponentId {
                return component
            }
        }
        return nil
    }
    
    func addCurrentComponents(component: DrawingComponent) {
        self.currentComponents.append(component)
    }
    
    func removeCurrentComponents(usersComponentId: String) {
        print("remove \(usersComponentId)")
        for i in 0..<currentComponents.count {
            if currentComponents[i].usersComponentId == usersComponentId {
                currentComponents.remove(at: i)
                break
            }
        }
    }
    
    func printCurrentComponents(status: String) {
        var str = "cc( \(status) ) [ \(currentComponents.count) ] = "
        for component in currentComponents {
            str += "\(component.id!) (\(component.usersComponentId!)) "
        }
        print(str)
    }
    
    func addDrawingComponents(component: DrawingComponent) {
        self.drawingComponents.append(component)
    }
    
    func addAllDrawingComponents(components: [DrawingComponent]) {
        self.drawingComponents.append(contentsOf: components)
    }

    /*func removeAllDrawingComponents(ids: [Int]) {
        for i in ids {
            self.removeDrawingComponents(id: i)
        }
    }*/

    func removeDrawingComponents(id: Int) -> Int {
        for i in 0..<drawingComponents.count {
            if drawingComponents[i].id == id {
                drawingComponents.remove(at: i)
                return i
            }
        }
        return -1
    }
    
    func printDrawingComponents(status: String) {
        var str = "dc( \(status) ) [ \(drawingComponents.count) ] = "
        for component in drawingComponents {
            str += "\(component.id!) (\(component.usersComponentId!)) "
        }
        print(str)
    }
    
    func findDrawingComponentById(id: Int) -> DrawingComponent? {
        for component in drawingComponents {
            if component.id == id {
                return component
            }
        }
        return nil
    }

    func findDrawingComponentByUsersComponentId(usersComponentId: String) -> DrawingComponent? {
        for component in drawingComponents {
            if component.usersComponentId == usersComponentId {
                return component
            }
        }
        return nil
    }
    
    func initDrawingBoardArray(width: Int, height: Int) {
        
        drawingBoardArray = Array(repeating: Array(repeating: [Int](), count: width), count: height)  // out of memory error
        print("initDrawingBoardArray() height=\(drawingBoardArray!.count) width=\(drawingBoardArray![0].count)")
        
        for i in 0..<height {
            for j in 0..<width {
                drawingBoardArray![i][j].append(-1)
            }
        }
    }

    func clearDrawingBoardArray() {
        for i in 0..<drawingBoardArray!.count {
            for j in 0..<drawingBoardArray![i].count {
                if drawingBoardArray![i][j].count != 1 {
                    drawingBoardArray![i][j].removeAll()
                    drawingBoardArray![i][j].append(-1)
                }
            }
        }
    }
    
    //drawingComponent 점 펼치기 --> drawingBoardArray
    func splitPoints(component: DrawingComponent, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        //if component == nil { return }
        if component.type == nil { return }
        
        component.calculateRatio(myCanvasWidth: canvasWidth, myCanvasHeight: canvasHeight);
        var newPoints = [Point]()
        
        switch component.type {
        case .STROKE:
            if strokeSplitPoints(component: component) == nil { return }
            newPoints = strokeSplitPoints(component: component)!
            break
            
        case .RECT, .OVAL:  //정교하게 수정 x^2/a^2 + y^2/b^2 <= 1
            newPoints = rectSplitPoints(component: component)
            break
        case .none: break
            
        }
        
        drawingBoardMap.updateValue(newPoints, forKey: component.id!)
        
        for point in newPoints {
            let x = point.x
            let y = point.y
            
            if(!drawingBoardArray![y][x].contains(component.id!)) {
                drawingBoardArray![y][x].append(component.id!)
            }
        }
    }
    //Log.i("drawing", "newPoints = " + newPoints.toString());
    
    
    func strokeSplitPoints(component: DrawingComponent) -> [Point]? {
        
        var calcPoints = [Point]()    //화면 비율 보정한 Point 배열
        for point in component.points {
            let x = point.x
            let y = point.y
            calcPoints.append(Point(x: x * Int(component.xRatio), y: y * Int(component.yRatio)))
        }
        //print("calcPoints = \(calcPoints)")
        
        var newPoints = [Point]()     //사이 점 채워진 Point 배열
        var slope: Int?       //기울기
        var yIntercept: Int?  //y절편
        
        if calcPoints.count < 2 { return nil }
        
        for i in 0..<calcPoints.count-1 {
            let from = calcPoints[i]
            let to = calcPoints[i+1]
            
            slope = (to.x - from.x) == 0 ? 0 : Int(to.y - from.y) / Int(to.x - from.x)
            yIntercept = (from.y - (slope! * from.x));
            
            if from.x <= to.x {
                for x in from.x..<to.x {
                    let y = ((slope! * x) + yIntercept!)
                    newPoints.append(Point(x: x, y: y))
                }
            } else {
                for x in to.x..<from.x {
                    let y = ((slope! * x) + yIntercept!)
                    newPoints.append(Point(x: x, y: y))
                }
            }
        }
        
        return newPoints
    }
    
    func rectSplitPoints(component: DrawingComponent) -> [Point] {   //테두리만

        let calcBeginPoint = Point(x: component.beginPoint!.x * Int(component.xRatio), y: component.beginPoint!.y * Int(component.yRatio))
        let calcEndPoint = Point(x: component.endPoint!.x * Int(component.xRatio), y: component.endPoint!.y * Int(component.yRatio))
        print("calcBegin = \(calcBeginPoint), calcEnd = \(calcEndPoint)")

        let width = abs(calcEndPoint.x - calcBeginPoint.x)
        let height = abs(calcEndPoint.y - calcBeginPoint.y)

        let datumPoint:Point = (calcBeginPoint.x < calcEndPoint.x) ? calcBeginPoint : calcEndPoint; //기준점 (사각형의 왼쪽위 꼭짓점)

        var newPoints = [Point]()     //사이 점 채워진 Point 배열
        let slope:Int = (calcEndPoint.x - calcBeginPoint.x) == 0 ? 0 : (calcEndPoint.y - calcBeginPoint.y) / (calcEndPoint.x - calcBeginPoint.x);

        if(slope == 0) {
            newPoints.append(calcBeginPoint)
        } else if(slope < 0) {
            datumPoint.y -= height;
        }

        //component.beginPoint = calcBeginPoint
        //component.endPoint = calcEndPoint
        component.datumPoint = Point(x: datumPoint.x / Int(component.xRatio), y: datumPoint.y / Int(component.yRatio))
        component.width = width
        component.height = height

        for i in datumPoint.y..<datumPoint.y + height + 1 {
            newPoints.append(Point(x: datumPoint.x, y: i))
            newPoints.append(Point(x: datumPoint.x + width, y: i))
        }
        for i in datumPoint.x..<datumPoint.x + width + 1 {
            newPoints.append(Point(x: i, y: datumPoint.y))
            newPoints.append(Point(x: i, y: datumPoint.y + height))
        }

        //print("\(newPoints)")
        return newPoints;
    }
    
    func addHistory(item: DrawingItem) {
        history.append(item)
    }
    
    func clearUndoArray() { //redo 방지
        undoArray.removeAll()
        //drawingVC.redoBtn.setEnabled(false)
    }
    
    func findEnclosingDrawingComponents(point: Point) -> [Int] {
        var erasedComponentIds = [Int]()
        erasedComponentIds.append(-1)
        
        for component in drawingComponents {
            if component.type == nil { return erasedComponentIds }
            switch component.type {
            case .STROKE: break
                
            case .RECT, .OVAL:
                let datumPoint = Point(x: Int(CGFloat(component.datumPoint!.x) * component.xRatio), y: Int(CGFloat(component.datumPoint!.y) * component.yRatio))
                
                let width = component.width
                let height = component.height
                if (datumPoint.x <= point.x && point.x <= datumPoint.x + width!) && (datumPoint.y <= point.y && point.y <= datumPoint.y + height!) {
                    erasedComponentIds.append(component.id!)
                }
            case .none: break
            }
        }
        
        return erasedComponentIds
    }
    
    func addRemovedComponentIds(ids: [Int]) {
        for i in ids {
            if !removedComponentId.contains(i) {
                removedComponentId.append(i)
            }
        }
    }

    func removeRemovedComponentIds(ids: [Int]) {
        for i in 0..<ids.count {
            if removedComponentId.contains(ids[i]) {
                removedComponentId.remove(at: i)
            }
        }
    }

    func getNotRemovedComponentIds(ids: [Int]) -> [Int] {
        var temp = [Int]()
        for i in 0..<ids.count {
            if !removedComponentId.contains(ids[i]) {
                temp.append(ids[i])
            }
        }
        return temp
    }
    
    func isContainsRemovedComponentIds(ids: [Int]) -> Bool {
        var flag = true
        for i in 1..<ids.count {
            if !removedComponentId.contains(ids[i]) {
                flag = false
            }
        }
        return flag
    }
    
    func eraseDrawingBoardArray(erasedComponentIds: [Int]) {
        for i in 1..<erasedComponentIds.count {
            let id = erasedComponentIds[i]

            let newPoints = drawingBoardMap[id]
            if newPoints == nil { return }

            print("id=\(id), newPoints.size()=\(newPoints!.count)")

            for j in 0..<newPoints!.count {
                let x = newPoints![j].x
                let y = newPoints![j].y

                if drawingBoardArray![y][x].contains(id) {
                    let index = drawingBoardArray![y][x].index(of: id)
                    drawingBoardArray![y][x].remove(at: index!)
                }
            }
            drawingBoardMap.removeValue(forKey: id)
        }
    }
    
    func clearDrawingBitmap() {
        UIGraphicsBeginImageContext(drawingView!.frame.size)
        drawingView!.image = nil
        UIGraphicsEndImageContext()
    }
}


extension UIColor {
    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)
            
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}
