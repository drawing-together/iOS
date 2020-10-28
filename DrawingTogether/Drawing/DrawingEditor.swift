//
//  DrawingEditor.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

class DrawingEditor {
    static let INSTANCE = DrawingEditor()
    private init() {  }
    
    let parser = JSONParser.parser
    
    var drawingView: DrawingView?
    var drawingVC: DrawingViewController?
    
    var receiveImage: UIImage?
    var currentImage: UIImage?
    var frameSize: CGSize?
    
    //    var backgroundImage: CGImage?
    
    var isIntercept = false
    
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
    var fillColor: String! = "#000000"
    var strokeColor: String! = "#000000"
    var strokeAlpha = 255
    var fillAlpha = 0
    var strokeWidth: CGFloat = 10
    var penMode: PenMode?
    var highlightAlpha = 130
    var normalAlpha = 255
    
    // MARK: 셀렉터
    var selectedComponent: DrawingComponent?
    var preSelectedComponents = [DrawingComponent]()
    var postSelectedComponents = [DrawingComponent]()
    //var preSelectedComponentsImage = UIImage()
    var unselectedComponentsView = UIImageView()
    var selectedBorderColor = UIColor.lightGray
    var mySelectedBorderColor = UIColor.gray
    
    // MARK: 텍스트에 필요한 객체
    var texts: [Text] = []
    var currentText: Text?
    var isTextBeingEditied = false
    var maxTextId: Int = -1
    
    var isMidEntered = false
    
    // MARK: 텍스트 속성
    var textSize = 20
    var textColor = "#000000"
    
    // MARK: 이미지
    var backgroundImage: [Int8]?
    
    var autoDrawList: [AutoDraw] = []
    var autoDrawImageList: [UIImageView] = []
    
    func initialize(drawingVC: DrawingViewController, master: Bool) {
        self.drawingVC = drawingVC
        self.drawingView = drawingVC.drawingView
        currentType = ComponentType.STROKE
        penMode = PenMode.NORMAL
        currentMode = Mode.DRAW
        myCanvasWidth = drawingView!.bounds.size.width
        myCanvasHeight = drawingView!.bounds.size.height
        
        unselectedComponentsView.frame = drawingView!.frame
        frameSize = CGSize(width: myCanvasWidth!, height: myCanvasHeight!)
        
        if(drawingBoardArray == nil) {
            print("drawingview width=\(Int(myCanvasWidth!)), height=\(Int(myCanvasHeight!))")
            initDrawingBoardArray(width: Int(myCanvasWidth!), height: Int(myCanvasHeight!))
        }
        if(master) {
            print("progressDialog dismiss")
            SVProgressHUD.dismiss()
        }
    }
    
    func removeAllDrawingData() {
        selectedComponent = nil
        //deselect(updateImage: false)
        preSelectedComponents.removeAll()
        postSelectedComponents.removeAll()
        
        componentId = -1
        maxComponentId = -1
        removedComponentId.removeAll()
        clearDrawingBoardArray()
        drawingBoardMap.removeAll()
        
        drawingComponents.removeAll()
        currentComponents.removeAll()
        
        removeAllTextLabelToDrawingContainer() // 텍스트 제거
        texts.removeAll() // 텍스트 자료구조 삭제
        currentText = nil
        
        history.removeAll()
        undoArray.removeAll()
        
        currentMode = Mode.DRAW
        currentType = ComponentType.STROKE
        penMode = PenMode.NORMAL
        strokeColor = "#000000"
        strokeWidth = 10
        
        isIntercept = false
        
        backgroundImage = nil
        drawingVC!.backgroundImageView.image = nil
    }
    
    
    // MARK: Drawing FUNCTION
    func drawAllDrawingComponents() {
        drawingComponents = drawingComponents.sorted(by: {$0.id! < $1.id!})
        
        for component in drawingComponents {
            component.drawComponent(view: drawingView!, drawingEditor: self)
        }
    }
    
    func drawOthersCurrentComponent(username: String?) {
        if username == nil {
            for component in currentComponents {
                if component.username != self.myUsername {
                    component.drawComponent(view: drawingVC!.currentView, drawingEditor: self)
                }
            }
        } else {
            for component in currentComponents {
                if ((component.username != self.myUsername) && (component.username != username)) {
                    component.drawComponent(view: drawingVC!.currentView, drawingEditor: self)
                }
            }
        }
        
    }
    
    func drawAllDrawingComponentsForMid() {   //drawingComponents draw
        //print("drawn width=\((drawingComponents[0].drawnCanvasWidth)!), height=\((drawingComponents[0].drawnCanvasHeight)!)")
        for component in drawingComponents {
            
            component.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
            component.drawComponent(view: drawingView!, drawingEditor: self)
            
            splitPoints(component: component, canvasWidth: CGFloat(drawingBoardArray![0].count), canvasHeight: CGFloat(drawingBoardArray!.count));
        }
        
        print("drawingBoardArray[][] w=\(drawingBoardArray![0].count), h=\(drawingBoardArray!.count)")
        //print("dba[0][0] = \(drawingBoardArray![0][0][0])")
    }
    
    func printDrawingComponentArray(name: String, array: [DrawingComponent], status: String) {
        var str = "\(name)( \(status) ) [ \(array.count) ] = "
        for component in array {
            str += "\(component.id!) (\(component.usersComponentId!)) "
        }
        print(str)
    }
    
    func isContainsAllDrawingComponents(ids: [Int]) -> Bool {
        for i in ids {
            if !isContainsDrawingComponents(id: i) { return false }
        }
        return true
    }
    
    func isContainsDrawingComponents(id: Int) -> Bool {
        for component in drawingComponents {
            if component.id == id { return true }
        }
        return false
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
    
    /*func printCurrentComponents(status: String) {
     var str = "cc( \(status) ) [ \(currentComponents.count) ] = "
     for component in currentComponents {
     str += "\(component.id!) (\(component.usersComponentId!)) "
     }
     print(str)
     }*/
    
    func addDrawingComponents(component: DrawingComponent) {
        self.drawingComponents.append(component)
    }
    
    func addAllDrawingComponents(components: [DrawingComponent]) {
        self.drawingComponents.append(contentsOf: components)
    }
    
    func removeAllDrawingComponents(ids: [Int]) {
        for i in ids {
            self.removeDrawingComponents(id: i)
        }
    }
    
    func removeDrawingComponents(id: Int) -> Int {
        for i in 0..<drawingComponents.count {
            if drawingComponents[i].id == id {
                drawingComponents.remove(at: i)
                return i
            }
        }
        return -1
    }
    
    func removeDrawingComponents(usersComponentId: String) {
        for i in 0..<drawingComponents.count {
            if drawingComponents[i].usersComponentId == usersComponentId {
                drawingComponents.remove(at: i)
                return
            }
        }
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
        
    }
    
    func clearDrawingBoardArray() {
        for i in 0..<drawingBoardArray!.count {
            for j in 0..<drawingBoardArray![i].count {
                autoreleasepool {
                if drawingBoardArray![i][j].count != 0 {
                    drawingBoardArray![i][j].removeAll()
                }
                }
            }
        }
    }
    
    //drawingComponent 점 펼치기 --> drawingBoardArray
    func splitPoints(component: DrawingComponent, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        //if component == nil { return }
        if component.type == nil { return }
        
        component.calculateRatio(myCanvasWidth: canvasWidth, myCanvasHeight: canvasHeight)
        var newPoints = [Point]()
        
        switch component.type {
        case .STROKE:
            if let points = strokeSplitPoints(component: component) {
                newPoints = points
            }
            break
            
        case .RECT, .OVAL:  //정교하게 수정 x^2/a^2 + y^2/b^2 <= 1
            newPoints = rectSplitPoints(component: component)
            break
        case .none: break
            
        }
        
        drawingBoardMap.updateValue(newPoints, forKey: component.id!)
        
        /*var str = "newPoints(\(newPoints.count)) = "
         for point in newPoints {
         str += "\(point.toString()) "
         }
         print(str)*/
        
        for point in newPoints {
            autoreleasepool {
                if point.y > 0 && point.x > 0 && point.y < Int(myCanvasHeight!) && point.x < Int(myCanvasWidth!) {
                    let x = point.x
                    let y = point.y
                    
                    if(!drawingBoardArray![y][x].contains(component.id!)) {
                        drawingBoardArray![y][x].append(component.id!)
                    }
                }
            }
        }
    }
    
    func strokeSplitPoints(component: DrawingComponent) -> [Point]! {
        
        var calcPoints = [Point]()    //화면 비율 보정한 Point 배열
        for point in component.points {
            autoreleasepool {
            let x = point.x
            let y = point.y
            calcPoints.append(Point(x: Int(CGFloat(x) * (component.xRatio)), y: Int(CGFloat(y) * (component.yRatio))))
            }
        }
        
        var str = "stroke calcPoints(\(calcPoints.count)) = "
        for point in calcPoints {
            str += "\(point.toString()) "
        }
        //print(str)
        
        var newPoints = [Point]()     //사이 점 채워진 Point 배열
        var slope: Int?       //기울기
        var yIntercept: Int?  //y절편
        
        if calcPoints.count < 2 {
            newPoints.append(Point(x: calcPoints[0].x, y: calcPoints[0].y))
            return newPoints
        }
        
        for i in 0..<calcPoints.count-1 {
            autoreleasepool {
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
        }
        
        return newPoints
    }
    
    
    func rectSplitPoints(component: DrawingComponent) -> [Point] {   //테두리만
        
        let calcBeginPoint = Point(x: Int(CGFloat(component.beginPoint!.x) * (component.xRatio)), y: Int(CGFloat(component.beginPoint!.y) * (component.yRatio)))
        let calcEndPoint = Point(x: Int(CGFloat(component.endPoint!.x) * (component.xRatio)), y: Int(CGFloat(component.endPoint!.y) * (component.yRatio)))
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
        component.datumPoint = Point(x: Int(CGFloat(datumPoint.x) / (component.xRatio)), y: Int(CGFloat(datumPoint.y) / (component.yRatio)))
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
    
    func addUndoArray(item: DrawingItem) {
        undoArray.append(item)
    }
    
    func clearUndoArray() { //redo 방지
        undoArray.removeAll()
        drawingVC!.setRedoEnabled(isEnabled: false)
    }
    
    var itemIds = [Int]()
    func updateDrawingItem(lastItem: DrawingItem, isUndo: Bool) {
        print("mode = \(String(describing: lastItem.mode))")
        
        switch lastItem.mode {
        case .DRAW, .ERASE:
            itemIds.removeAll()
            for component in lastItem.getComponents() {
                itemIds.append(component.id!)
            }
            print("last item ids = \(itemIds)")
            
            if(isContainsAllDrawingComponents(ids: itemIds)) {                           //erase
                print("update erase")
                clearDrawingImage()
                addRemovedComponentIds(ids: itemIds)
                removeAllDrawingComponents(ids: itemIds)
                drawAllDrawingComponents()
                eraseDrawingBoardArray(erasedComponentIds: itemIds)
            } else {
                print("update draw")
                for component in lastItem.getComponents() {    //draw
                    component.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
                    //component.drawComponent(getBackCanvas())
                    splitPoints(component: component, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                    //component.setIsErased(false)
                }
                removeRemovedComponentIds(ids: itemIds)
                addAllDrawingComponents(components: lastItem.getComponents())
                clearDrawingImage()
                drawAllDrawingComponents()
            }
            print("removedComponentIds = \(removedComponentId)")

            break
            
        case .SELECT:
            let comp = lastItem.getComponent()
                
                if isUndo {
                    print("undo history (\(comp.beginPoint!.x),\(comp.beginPoint!.y)), (\(lastItem.movePoint!.x),\(lastItem.movePoint!.y))")
                    moveSelectedComponent(selectedComponent: comp, moveX: -(lastItem.movePoint!.x), moveY: -(lastItem.movePoint!.y))
                    print("undo history (\(comp.beginPoint!.x),\(comp.beginPoint!.y))")
                } else {
                    print("redo history (\(comp.beginPoint!.x),\(comp.beginPoint!.y)), (\(lastItem.movePoint!.x),\(lastItem.movePoint!.y))")
                    moveSelectedComponent(selectedComponent: comp, moveX: (lastItem.movePoint!.x), moveY: (lastItem.movePoint!.y))
                     print("redo history (\(comp.beginPoint!.x),\(comp.beginPoint!.y))")
                    
                }
                comp.calculateRatio(myCanvasWidth: myCanvasWidth!, myCanvasHeight: myCanvasHeight!)
                splitPointsOfSelectedComponent(component: comp, canvasWidth: myCanvasWidth!, canvasHeight: myCanvasHeight!)
                updateSelectedComponent(newComponent: comp)
                clearDrawingImage()
                drawAllDrawingComponents()
            
            break
            
        case .none:
            break
        case .some(_):
            break
        }
        
    }
    
    func popHistory() -> DrawingItem {      //undo
        let index = history.count - 1
        let lastItem = history[index]
        history.remove(at: index)
        
        updateLastItem(lastItem: lastItem, isUndo: true)
        return lastItem
    }
    
    func popUndoArray() -> DrawingItem {    //redo
        let index = undoArray.count - 1
        let lastItem = undoArray[index]
        
        updateLastItem(lastItem: lastItem, isUndo: false)
        undoArray.remove(at: index)
        return lastItem
    }
    
    func updateLastItem(lastItem: DrawingItem, isUndo: Bool) {
        if lastItem.mode != nil {
            updateDrawingItem(lastItem: lastItem, isUndo: isUndo)
        } else if lastItem.textMode != nil {
            //
        }
    }
    
    func undo() {
        if history.count == 0 { return }
        
        undoArray.append(popHistory())
        
        if undoArray.count == 1 { drawingVC?.setRedoEnabled(isEnabled: true) }
        
        if history.count == 0 {
            drawingVC?.setUndoEnabled(isEnabled: false)
            clearDrawingImage()
            return
        }
        
        print("history.size()=\(history.count)")

    }
    
    func redo() {
        if undoArray.count == 0 { return }
        
        history.append(popUndoArray())
        
        if history.count == 1 { drawingVC?.setUndoEnabled(isEnabled: true) }
        if undoArray.count == 0 { drawingVC?.setRedoEnabled(isEnabled: false) }
        
        print("history.size()=\(history.count)")
    }
    
    func clearDrawingComponents() {
        autoreleasepool {
        selectedComponent = nil
        preSelectedComponents.removeAll()
        postSelectedComponents.removeAll()
            
        drawingView!.image = nil
        receiveImage = nil
        currentImage = nil
        unselectedComponentsView.image = nil
        
        undoArray.removeAll()
        history.removeAll()
        drawingComponents.removeAll()
        currentComponents.removeAll()
        componentId = -1
        maxComponentId = -1
        clearDrawingBoardArray()
        removedComponentId.removeAll()
        drawingBoardMap.removeAll()
        }
    }
    
    var erasedComponentIds = [Int]()
    func findEnclosingDrawingComponents(point: Point) -> [Int] {
        
        erasedComponentIds.removeAll()
        
        for component in drawingComponents {
        
            if component.type == nil { return erasedComponentIds }
            switch component.type {
            case .STROKE: break
                
            case .RECT, .OVAL:
                let datumPoint = Point(x: Int(CGFloat(component.datumPoint!.x) * component.xRatio), y: Int(CGFloat(component.datumPoint!.y) * component.yRatio))
                
                let width = component.width!
                let height = component.height!
                if (datumPoint.x <= point.x && point.x <= datumPoint.x + width) && (datumPoint.y <= point.y && point.y <= datumPoint.y + height) {
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
            autoreleasepool {
            if removedComponentId.contains(ids[i]) {
                removedComponentId.remove(at: i)
            }
            }
        }
    }
    
    var tempIds = [Int]()
    func getNotRemovedComponentIds(ids: [Int]) -> [Int] {
        tempIds.removeAll()
        for i in 0..<ids.count {
            autoreleasepool {
            if !removedComponentId.contains(ids[i]) {
                tempIds.append(ids[i])
            }
            }
        }
        return tempIds
    }
    
    func isContainsRemovedComponentIds(ids: [Int]) -> Bool {
        var flag = true
        //for i in 1..<ids.count {
        for i in 0..<ids.count {
            autoreleasepool {
            if !removedComponentId.contains(ids[i]) {
                flag = false
            }
            }
        }
        return flag
    }
    
    func eraseDrawingBoardArray(erasedComponentIds: [Int]) {
        //for i in 1..<erasedComponentIds.count {
        for i in 0..<erasedComponentIds.count {
            autoreleasepool {
            let id = erasedComponentIds[i]
            
            let newPoints = drawingBoardMap[id]
            if newPoints == nil { return }
            
            print("id=\(id), newPoints.size()=\(newPoints!.count)")
            
            for j in 0..<newPoints!.count {
                autoreleasepool {
                    if newPoints![j].y > 0 && newPoints![j].x > 0 && newPoints![j].y < Int(myCanvasHeight!) && newPoints![j].x < Int(myCanvasWidth!) {
                        let x = newPoints![j].x
                        let y = newPoints![j].y
                        
                        if drawingBoardArray![y][x].contains(id) {
                            if let index = drawingBoardArray?[y][x].firstIndex(of: id) {
                                drawingBoardArray?[y][x].remove(at: index)
                            }
                            //drawingBoardArray![y][x] = drawingBoardArray![y][x].filter() { $0 != id }
                        }
                    }
                }
            }
            drawingBoardMap.removeValue(forKey: id)
            }
        }
    }
    
    func clearDrawingImage() {
        //UIGraphicsBeginImageContext(drawingView!.frame.size)
        drawingView!.image = nil
        //UIGraphicsEndImageContext()
        drawingView?.setNeedsDisplay()
    }
    
    func clearMyCurrentImage() {
        drawingVC?.myCurrentView.image = nil
        
    }
    
    func clearCurrentImage() {
        drawingVC?.currentView.image = nil
        
    }
    
    func deselect(updateImage: Bool) {
        if selectedComponent == nil { return }
        drawingView?.isSelected = false
        
        if let comp = selectedComponent, let sComp = findDrawingComponentByUsersComponentId(usersComponentId: comp.usersComponentId!) {
            sComp.isSelected = false
            comp.isSelected = false
            clearMyCurrentImage()
            if updateImage { updateDrawingImage(border: false) }
        }
    }
    
    func initSelectedImage() {
        if(drawingView!.isSelected) {
            deselect(updateImage: true)
            drawingView!.sendSelectMqttMessage(isSelected: false)
        }
    }
    
    func clearAllSelectedImage() {
        
    }
    
    func setDrawingComponentSelected(_ usersComponentId: String, isSelected: Bool) {
        for component in drawingComponents {
            if component.usersComponentId == usersComponentId {
                component.isSelected = isSelected
            }
        }
    }
    
    func setPreSelectedComponents(id: Int) {
        preSelectedComponents.removeAll()
        for component in drawingComponents {
            if let compId = component.id, compId < id {
                preSelectedComponents.append(component)
            }
        }
        
        var str = "pre selected = "
        for component in preSelectedComponents {
            str += "\(component.id!) "
        }
        print(str)
    }
    
    func setPostSelectedComponents(id: Int) {
        postSelectedComponents.removeAll()
        tempPostSelectedComponents.removeAll()
        for component in drawingComponents {
            if let compId = component.id, compId > id {
                postSelectedComponents.append(component)
            }
        }
        
        var str = "post selected = "
        for component in postSelectedComponents {
            str += "\(component.id!) "
        }
        print(str)
    }
    
    func isContainsSelectedComponent(point: Point) -> Bool {
        if let component = selectedComponent, component.type != ComponentType.STROKE {
            
            let datumPoint = Point(x: Int(CGFloat(component.datumPoint!.x) * component.xRatio), y: Int(CGFloat(component.datumPoint!.y) * component.yRatio))
            
            let width = component.width
            let height = component.height
            if (datumPoint.x <= point.x && point.x <= datumPoint.x + width!) && (datumPoint.y <= point.y && point.y <= datumPoint.y + height!) {
                return true
            }
        }
        return false
    }
    
    func drawSelectedComponentBorder(component: DrawingComponent, color: CGColor) {
        //component.calculateRatio(canvasWidth, canvasHeight);
        let strokeWidth = component.strokeWidth
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: myCanvasWidth!, height: myCanvasHeight!), false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawingVC?.myCurrentView?.image?.draw(in: drawingVC!.myCurrentView!.bounds)
        
        let from = component.beginPoint
        let to = component.endPoint
        //let width = (to!.x - from!.x) == 0 ? 1 : abs(to!.x - from!.x)
        //let height = (to!.y - from!.y) == 0 ? 1 : abs(to!.y - from!.y)
        let width = abs(to!.x - from!.x)
        let height = abs(to!.y - from!.y)
        
        var datum:Point = (from!.x < to!.x) ? from! : to! //기준점 (사각형의 왼쪽위 꼭짓점)
        let slope:Float = Float(to!.x - from!.x) == 0 ? 0 : Float(to!.y - from!.y) / Float(to!.x - from!.x)
        
        if slope == 0 {
            if (to!.x - from!.x) == 0 {
                datum = (from!.y < to!.y) ? from! : to!
            }
        } else if slope < 0 {
            datum = Point(x: datum.x, y: datum.y - height)
        }
        
        //let rect = CGRect(x: CGFloat(datum.x) * xRatio, y: CGFloat(datum.y) * yRatio, width: CGFloat(width) * xRatio, height: CGFloat(height) * yRatio)
        
        let rX: CGFloat = CGFloat(datum.x) * component.xRatio - strokeWidth! / 4 - 5
        let rY: CGFloat = CGFloat(datum.y) * component.yRatio - strokeWidth! / 4 - 5
        let rW: CGFloat = CGFloat(width) * component.xRatio + strokeWidth! / 2 + 10
        let rH: CGFloat = CGFloat(height) * component.yRatio + strokeWidth! / 2 + 10
        
        let rect = CGRect(x: rX, y: rY , width: rW, height: rH)
        
        //print("shape drawComponent datum=\(String(describing: datum.toString())), width=\(String(describing: width)), height=\(String(describing: height))")
        
        let  dashes: [ CGFloat ] = [ 7.0, 5.0 ]
        context.setLineDash(phase: 4.0, lengths: dashes)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(4 / 2)     // **
        context.setStrokeColor(color)   // **
        context.setAlpha(1.0)
        context.stroke(rect)
        
        context.strokePath()
        drawingVC?.myCurrentView?.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func setPreAndPostSelectedComponentsImage() {
        //postSelectedComponents.append(contentsOf: tempPostSelectedComponents)
        unselectedComponentsView.image = nil
        for component in preSelectedComponents {
            component.drawComponent(view: unselectedComponentsView, drawingEditor: self)
            //component.drawComponent(view: drawingView!, drawingEditor: self)
        }
        for component in postSelectedComponents {
            component.drawComponent(view: unselectedComponentsView, drawingEditor: self)
            //component.drawComponent(view: drawingView!, drawingEditor: self)
        }
    }
    
    var tempPostSelectedComponents = [DrawingComponent]()
    func addPostSelectedComponent(component: DrawingComponent) {
        postSelectedComponents.append(component)
        //tempPostSelectedComponents.append(component)
        //component.drawComponent(view: unselectedComponentsView, drawingEditor: self)
        //component.drawComponent(view: drawingView!, drawingEditor: self)
    }
    
    func drawUnselectedComponents() {
        drawingView!.image = unselectedComponentsView.image
    }
    
    func updateSelectedComponent(newComponent: DrawingComponent) {    //속성 변경 update
        removeDrawingComponents(usersComponentId: newComponent.usersComponentId!)
        drawingComponents.append(newComponent)
    }
    
    func moveSelectedComponent(selectedComponent: DrawingComponent, moveX: Int, moveY: Int) {
        selectedComponent.beginPoint = Point(x: selectedComponent.beginPoint!.x + moveX, y: selectedComponent.beginPoint!.y + moveY)
        selectedComponent.endPoint = Point(x: selectedComponent.endPoint!.x + moveX, y: selectedComponent.endPoint!.y + moveY)
        selectedComponent.datumPoint = Point(x: selectedComponent.datumPoint!.x + moveX/*(int)(moveX*selectedComponent.getXRatio())*/, y: selectedComponent.datumPoint!.y + moveY/*(int)(moveY*selectedComponent.getYRatio())*/)
    }
    
    func updateDrawingImage(border: Bool) {
        drawingView?.image = nil
        drawAllDrawingComponents()
        if border, let component = selectedComponent {
            drawSelectedComponentBorder(component: component, color: mySelectedBorderColor.cgColor)
        }
    }
    
    func splitPointsOfSelectedComponent(component: DrawingComponent, canvasWidth: CGFloat, canvasHeight: CGFloat) {
        if component.type == nil { return }
        
        var id = [Int]()
        //id.append(-1)
        id.append(component.id!)
        eraseDrawingBoardArray(erasedComponentIds: id)
        
        component.calculateRatio(myCanvasWidth: canvasWidth, myCanvasHeight: canvasHeight);
        var newPoints = [Point]()
        
        if component.type == ComponentType.STROKE { return }
        
        let datumPoint = Point(x: Int(CGFloat(component.datumPoint!.x) * (component.xRatio)), y: Int(CGFloat(component.datumPoint!.y) * (component.yRatio)))
        let width = component.width!
        let height = component.height!
        
        for i in datumPoint.y..<datumPoint.y + height {
            newPoints.append(Point(x: datumPoint.x, y: i))
            newPoints.append(Point(x: datumPoint.x + width - 1, y: i))
        }
        for i in datumPoint.x..<datumPoint.x + width {
            newPoints.append(Point(x: i, y: datumPoint.y))
            newPoints.append(Point(x: i, y: datumPoint.y + height - 1))
        }
        
        drawingBoardMap.updateValue(newPoints, forKey: component.id!)
        
        /*UIGraphicsBeginImageContextWithOptions(CGSize(width: myCanvasWidth!, height: myCanvasHeight!), false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawingVC?.myCurrentView?.image?.draw(in: drawingVC!.myCurrentView!.bounds)
        let rect = CGRect(x: datumPoint.x, y: datumPoint.y, width: width, height: height)
        context.setLineWidth(4)
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.stroke(rect)
        context.strokePath()
        drawingVC?.myCurrentView?.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()*/
        
        for point in newPoints {
            if point.y > 0 && point.x > 0 && point.y < Int(myCanvasHeight!) && point.x < Int(myCanvasWidth!) {
                let x = point.x
                let y = point.y
                
                if(!drawingBoardArray![y][x].contains(component.id!)) {
                    drawingBoardArray![y][x].append(component.id!)
                }
            }
            //print("(\(x), \(y))")
        }
    }
    
    
    
    
    // MARK: TEXT FUNCTION
    func setTextStringId() -> String {
        maxTextId+=1
        print("\(myUsername!)-\(maxTextId)")
        print("\(maxTextId)")
        return ("\(myUsername!)-\(maxTextId)")
    }
    
    func findTextById(id: String) -> Text? {
        for idx in 0..<texts.count {
            if texts[idx].textAttribute.id == id {
                return texts[idx]
            }
        }
        return nil
    }
    
    func removeTexts(text: Text) {
        for idx in 0..<texts.count {
            if texts[idx] == text {
                texts.remove(at: idx)
                return
            }
        }
    }
    
    func addAllTextLabelToDrawingContainer() {
        for text in texts {
            
            // fixme nayeon
            // 다른 사용자(마스터)가 편집중일 텍스트일 경우 , TextAttribute 의 String text 는 계속해서 변하는 중
            // 그리고 텍스트 테두리 설정 안 되어 있음
            //            if(t.getTextAttribute().getUsername() != null) {
            //                t.getTextView().setText(t.getTextAttribute().getPreText()); // 이전 텍스트로 설정
            //                t.getTextView().setBackground(this.textFocusBorderDrawable); // 테두리 설정
            //            }
            //            // 중간에 들어왔는데 색상
            //
            //            // fixme nayeon
            //            t.setTextViewInitialPlace(t.getTextAttribute());
            //            t.setTextViewProperties();
            
            text.sizeToFit() // fixme nayeon - (1) set view properties (2) set initial place 순서 중요 !!
            drawingVC?.drawingContainer.addSubview(text)
            
        }
    }
    
    func removeAllTextLabelToDrawingContainer() {
        for text in texts {
            text.removeFromSuperview()
        }
    }
    
    // MARK: 배경 이미지
    func convertUIImage2ByteArray(image: UIImage) -> [Int8] { // UIImage -> Byte Array
        // UIImage -> NSData
        let imageData = image.jpegData(compressionQuality: 0.1)!
        
        return imageData.map { Int8(bitPattern: $0) }
    }
    
    func convertByteArray2UIImage(byteArray: [Int8]) -> UIImage { // Byte Array -> UIImage
        // Byte Array의 길이 구하기
        let count = byteArray.count
        // NSData 생성, Byte Array -> NSData
        let imageData: NSData = NSData(bytes: byteArray, length: count)
        // NSData -> UIImage
        let image: UIImage = UIImage(data: imageData as Data)!
        
        return image
    }
    
    func addAutoDraw(autoDraw: AutoDraw) {
        self.autoDrawList.append(autoDraw)
    }
    
    func setAutoDrawList(autoDrawList: [AutoDraw]) {
        self.autoDrawList = autoDrawList
    }
    
    func clearBackgroundImage() {
        backgroundImage =  nil
        drawingVC?.backgroundImageView.image = nil
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
