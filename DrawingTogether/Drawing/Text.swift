//
//  Text.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/09.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class Text: UILabel {
    
    var de: DrawingEditor = DrawingEditor.INSTANCE
    var client: MQTTClient = MQTTClient.client
    var parser: JSONParser = JSONParser.parser
    
    var drawingVC: DrawingViewController!
    
    var drawingContainer: UIView!
    var textEditingView: TextEditingView!
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var tapGestureRecognizer: UITapGestureRecognizer!
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    var textAttribute: TextAttribute!
    
    var xRatio: CGFloat = 1.0
    var yRatio: CGFloat = 1.0
    
    let MAX_MOVE: Int = 5
    var moveCounter: Int = -1
    
    
    func create(textAttribute: TextAttribute, drawingVC: DrawingViewController) {
        
        self.drawingVC = drawingVC
        
        self.drawingContainer = drawingVC.drawingContainer
        self.textEditingView = drawingVC.textEditingView
        self.textAttribute = textAttribute
                
        setLabelAttribute()
        setLabelInitialLocation(textAttr: self.textAttribute)
        
        // MARK: set gesture recognizers
        // 텍스트 이동
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panAction))
        self.isUserInteractionEnabled = true
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)
        
        // 텍스트 편집
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tapGestureRecognizer)
        
        // 텍스트 색상 변경
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        self.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func sendMqttMessage(textMode: TextMode) {
        let message = MqttMessageFormat(username: de.myUsername!, mode: .TEXT, type: de.currentType!, textAttr: self.textAttribute, textMode: textMode, myTextArrayIndex: de.texts.count-1)
        client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
    }
    
    func setTextAttribute() {
        self.textAttribute.username = de.myUsername
        self.textAttribute.generatedLayoutWidth = Int(drawingContainer.frame.width)
        self.textAttribute.generatedLayoutHeight = Int(drawingContainer.frame.height)
    }
    
    // TextView Properties -> Label Properties
    func setLabelAttribute() {
        self.text = textAttribute.text ?? ""
        self.backgroundColor = UIColor.clear
        self.textColor = UIColor(hexString: textAttribute.textColor!)
        self.font = UIFont.boldSystemFont(ofSize: (CGFloat)(textAttribute.textSize!))
        self.textAlignment = .center
        
        self.numberOfLines = 0
    }
    
    // Label Properties -> TextView Properties
    func setTextViewAttribute() {
        textEditingView.textView.text = textAttribute.text!
        textEditingView.textView.backgroundColor = UIColor.clear
        textEditingView.textView.textColor = UIColor(hexString: textAttribute.textColor!)
        textEditingView.textView.font = UIFont.boldSystemFont(ofSize: (CGFloat)(textAttribute.textSize!))
        textEditingView.textView.textAlignment = .center
    }
    
    
    // Label이 초기에 놓일 자리
    func setLabelInitialLocation(textAttr: TextAttribute) {
        
        if textAttr.isTextInited && textAttr.isTextMoved {
            print("set label initial place moved")
            setMovedLabelLocation()
        }
            
        else {
            print("set label initial place not moved")
            setNotMovedLabelLocation()
        }
    }
    
    
    /* 생성 후 움직이지 않은 텍스트 위치 지정 [화면 중앙에 위치] */
    func setNotMovedLabelLocation() {
        // Label의 가로 크기는 고정 (세로 크기는 내용에 맞게 정해짐)
        
        self.sizeToFit()
        
        // 드로잉 뷰 크기를 계산하여 레이블을 중앙에 위치시킴
        let w = drawingContainer.frame.width/3
        let h = self.frame.height // after sizeToFit

        let x = drawingContainer.frame.maxX/2 - (w/2)
        let y = drawingContainer.frame.maxY/2 - (h/2)
        
        print("[* set not moved label location]")
        print("drawing container = \(drawingContainer.frame.width), \(drawingContainer.frame.height)")

        self.frame = CGRect(x: x, y: y, width: w, height: h)
        
    }
    
    /* 생성 후 움직여진 텍스트 위치 지정 [x,y 좌푯값이 존재] */
    func setMovedLabelLocation() {
        
        self.sizeToFit()
        
        let w = drawingContainer.frame.width/3
        let h = self.frame.height

        calculateRatio(myViewWidth: drawingContainer.frame.width, myViewHeight: drawingContainer.frame.height)

        let x = (CGFloat)(textAttribute.x!) * xRatio - (w/2)
        let y = (CGFloat)(textAttribute.y!) * yRatio - (h/2)

//        print("xRatio=\(xRatio) yRatio=\(yRatio)")
//        print("label width=\(w) label height=\(h)")
//        print("container width=\(drawingContainer.frame.maxX) container height=\(drawingContainer.frame.maxY)")
//        print("calc x=\(x) calc y=\(y)")

        self.frame = CGRect(x: x, y: y, width: w, height: h)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("text touches began")
        
        // 1. 중간에 다른 사용자가 들어오는 중일 경우 텍스트 터치 막기
        // 2. 텍스트에 다른 사용자 이름이 지정되어 있으면
        // 텍스트 사용불가 (다른 사람이 사용중) - 이름이 null 일 경우만 사용 가능
        // 3. 현재 사용자가 한 텍스트 편집 중이라면, 다른 텍스트 편집 불가능 (한 번에 한 텍스트만 편집 가능)
        
        if de.isMidEntered {
            print("다른 사용자가 접속 중 입니다 잠시만 기다려주세요")
            drawingVC.showToast(message: "다른 사용자가 접속 중 입니다 잠시만 기다려주세요")
            
            enableGestures(false)
            
            return
        }
            
        else if (textAttribute.username != nil && !(textAttribute.username == de.myUsername)) {
            print("다른 사용자가 편집중인 텍스트입니다")
            drawingVC.showToast(message: "다른 사용자가 편집중인 텍스트입니다")
            
            enableGestures(false)
            
            return
        }
            
        else if de.isTextBeingEditied {
            print("편집 중에는 다른 텍스트를 사용할 수 없습니다")
            drawingVC.showToast(message: "편집 중에는 다른 텍스트를 사용할 수 없습니다")
            
            enableGestures(false)
            return
        }
            
        else if textAttribute.isTextChangedColor {
            print("텍스트 색상 변경중에는 움직일 수 없습니다")
            drawingVC.showToast(message: "텍스트 색상 변경중에는 움직일 수 없습니다")
            
            enableGestures(false)
            return
        }
        
        // 지우개 모드일 경우 텍스트 지우기
        if de.currentMode == .ERASE {
            eraseText()
            sendMqttMessage(textMode: .ERASE)
            
            return
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { // text touches began -> text touches moved -> pan begin
        print("text touches moved")
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { // touches move -> pan ( ended ) 안불림
        print("text touches ended")
        
        enableGestures(true)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("text touches cancelled")
    }
    
    func enableGestures(_ bool: Bool) -> Void {
        tapGestureRecognizer.isEnabled = bool
        panGestureRecognizer.isEnabled = bool
    }
    
    func activateTextEditing() {
        
        // disable drawing menu button
        
        de.currentText = self
        de.isTextBeingEditied = true // 현재 텍스트를 편집 중을 표시하는 플래그
        
        drawingVC.view.addSubview(textEditingView)
        
    }
    
    func deactivateTextEditing() {
        
        // enable drawing menu button
        
        de.isTextBeingEditied = false
        textEditingView.removeFromSuperview()
    }
    
    /* 텍스트 -> 텍스트 편집 화면 */
    func changeLabelToTextView() {
        de.currentMode = .TEXT
        
        self.textAttribute.username = de.myUsername
        self.textAttribute.text = self.text
        
        setTextViewAttribute()
        
        activateTextEditing()
    }
    
    /* 텍스트 편집 화면 -> 텍스트 */
    /* click done btn */
    func changeTextViewToLabel() -> Void {
        
        // 텍스트가 생성되고 처음 텍스트가 초기화 완료되는 시점에
        // 텍스트 사용 가능 설정을 하고 ( 초기 텍스트 입력이 완료되면 다른 사용자도 텍스트 조작 가능 )
        // MQTT 메시지 전송
        
        /* 새로운 텍스트에 대한 처리 [ LabelToTextView X (de.currentText 변경 필요 X) */
        if !(textAttribute.isTextInited) {
            
            // 사용자가 텍스트를 입력하지 않고 텍스트 완료 버튼 (Done Button)을 눌렀을 경우
            // 텍스트 생성하지 않기
            if isTextViewContentEmpty() {
                print("text view empty")
                deactivateTextEditing()
                de.currentMode = .DRAW
                return
            }
            
            textAttribute.username = nil // send mqtt message
            textAttribute.isTextInited = true
            textAttribute.text = textEditingView.textView.text! // 변경된 텍스트를 텍스트 속성 클래스에 저장
            setLabelAttribute() // Label 이 변경된 텍스트 속성(텍스트 문자열)을 가지도록 지정
//            de.currentText = nil // 현재 조작중인 텍스트 nil 처리
            
            
            setNotMovedLabelLocation() // MARK: 확인 필요
            
            de.texts.append(self)
            
            sendMqttMessage(textMode: .CREATE)  // 변경된 내용을 가진 TextAttribute 를 MQTT 메시지 전송
            
            deactivateTextEditing()
            
            // set label properties
            // ...
            
            drawingContainer.addSubview(self) // TextView 를 레이아웃에 추가
                        
            de.currentMode = .DRAW // 텍스트 편집이 완료 되면 현재 모드는 기본 드로잉 모드로
            
            return
        }
        
        // 기존에 있던 텍스트의 내용이 빈 경우 텍스트 지우기
        if isTextViewContentEmpty() {
            
            self.removeFromSuperview()
            deactivateTextEditing()
            eraseText()
            
            sendMqttMessage(textMode: .ERASE)
            
            de.currentMode = .DRAW // 텍스트 편집이 완료 되면 현재 모드는 기본 드로잉 모드로
            
            return
        }
        
        
        /* 기존에 있던 텍스트에 대한 처리 */
        textAttribute.username = nil
        
        textAttribute.text = textEditingView.textView.text
        setLabelAttribute()
        de.currentText = nil
        
        // sizeToFit()
        if textAttribute.x == nil || textAttribute.y == nil {
            setNotMovedLabelLocation()
        }
        else {
            setMovedLabelLocation()
        }
        
        deactivateTextEditing()
        
        // History
        
        sendMqttMessage(textMode: .DONE) // 사용 종료를 알리기 위해 보내야함 ( 사용자이름 : nil )
        
        de.currentMode = .DRAW // 텍스트 편집이 완료 되면 현재 모드는 기본 드로잉 모드로
        
    }
    
    func eraseText() -> Void {
        
        self.removeFromSuperview() // 화면에서 텍스트 제거
        de.removeTexts(text: self) // 텍스트 리스트에서 텍스트 제거
        
    }
    
    func startTextColorChange() -> Void {
        de.currentText = self // 현재 텍스트 지정
        setTextAttribute() // 텍스트 편집 전 사용자 이름 지정
        textAttribute.isTextChangedColor = true // 텍스트 컬러 변경중임을 나타내는 플래그 (텍스트 색상 변경 중에 움직이지 않도록)
        
        sendMqttMessage(textMode: .START_COLOR_CHANGE) // 다른 사용자의 텍스트 동시 처리 막기 위해 ( 이름, 테두리 설정 )
        
        // MARK: set background hightlight
        self.setLabelBorder(color: .orange)
        
        drawingVC.colorChangeBtnView.isHidden = false
        
        sendMqttMessage(textMode: .START_COLOR_CHANGE)
        
    }
    
    func finishTextColorChange() -> Void {
        textAttribute.username = nil
        textAttribute.isTextChangedColor = false
        
        sendMqttMessage(textMode: .FINISH_COLOR_CHANGE)
        
        // MARK: clear background hightlight
        self.setLabelBorder(color: .clear)
        
        drawingVC.colorChangeBtnView.isHidden = true
        
        de.currentMode = .DRAW
    }
        
    func isTextViewContentEmpty() -> Bool {
        return ( textEditingView.textView.text == "" || textEditingView.textView.text == textEditingView.placeholder )
    }
    
    
    func calculateRatio(myViewWidth: CGFloat, myViewHeight: CGFloat) {
        
        self.xRatio = (CGFloat)(myViewWidth) / (CGFloat)(self.textAttribute.generatedLayoutWidth!)
        self.yRatio = (CGFloat)(myViewHeight) / (CGFloat)(self.textAttribute.generatedLayoutHeight!)
        
        print("xRatio=\(xRatio) yRatio=\(yRatio)")
        print("container width=\(drawingContainer.frame.maxX) container height=\(drawingContainer.frame.maxY)")
    }
    
    func setLabelLocation() {
        calculateRatio(myViewWidth: drawingContainer.frame.width, myViewHeight: drawingContainer.frame.height)
        
        self.center = CGPoint(x: (CGFloat)(textAttribute.x!) * xRatio, y: (CGFloat)(textAttribute.y!) * yRatio)
        
        print("set label location = \(CGFloat(textAttribute.x!) * xRatio), \(CGFloat(textAttribute.y!) * yRatio)")
        print("text attribute  = \(textAttribute.x!), \(textAttribute.y!)")
        print("ratio  = \(xRatio), \(yRatio)")
    }
    
    func setLabelLocation(x: Int, y: Int) {
        calculateRatio(myViewWidth: drawingContainer.frame.width, myViewHeight: drawingContainer.frame.height)
        
        self.center = CGPoint(x: (CGFloat)(x) * xRatio, y: (CGFloat)(y) * yRatio)
        
        print("set label location (x, y) = \(CGFloat(textAttribute.x!) * xRatio), \(CGFloat(textAttribute.y!) * yRatio)")
        print("text attribute  = \(textAttribute.x!), \(textAttribute.y!)")
        print("ratio  = \(xRatio), \(yRatio)")
    }
    
    
    @objc func tapAction() {
        
        print("text tap gesture")

        
        // 1. 중간에 다른 사용자가 들어오는 중일 경우 텍스트 터치 막기
        // 2. 텍스트에 다른 사용자 이름이 지정되어 있으면
        //    텍스트 사용 불가 (다른 사람이 사용중) - TextAttribute의 username 프로퍼티가 nil 일 경우만 사용 가능
        // 3. 현재 사용자가 텍스트를 편집 중이라면, 다른 텍스트 편집 불가능 (한 번에 한 텍스트만 편집 가능)
        
        
        print(de.isMidEntered)
        print("\(textAttribute.username), \(de.myUsername)")
        print(de.isTextBeingEditied)

        changeLabelToTextView()
        
        sendMqttMessage(textMode: .MODIFY_START)
        
//        setTextViewAttribute()
//
//        drawingVC.view.addSubview(textEditingView)
    }
    
    /* 텍스트 색상 변경 */
    @objc func longPressAction() {
        print("text long press")
        
        de.currentMode = .TEXT
       
        startTextColorChange()
    }
    
    @objc func panAction() {
        
        print("text pan gesture")
        
        setTextAttribute()

        let transition = panGestureRecognizer.translation(in: self) // vector
                
        var changedX, changedY: Int
        var leftX, leftY, rightX, rightY: CGFloat
        
        leftX = self.center.x - self.frame.width/2 // 왼쪽 상단 x 좌표
        leftY = self.center.y - self.frame.height/2 // 왼쪽 상단 y좌표
        
        rightX = self.center.x + self.frame.width/2 // 오른쪽 하단 x좌표
        rightY = self.center.y + self.frame.height/2 // 오른쪽 하단 y좌표
        
        // 레이블의 중앙 좌푯값 + 제스쳐가 진행되는 벡터
        changedX = Int(self.center.x + transition.x)
        changedY = Int(self.center.y + transition.y)
        
        print("transition = \(transition.x), \(transition.y)")
        
        if leftX < 0 { // 좌측으로 넘어가는 경우
            changedX = Int(self.frame.width/2 + transition.x)
        }
        else if rightX > drawingContainer.frame.width { // 우측으로 넘어가는 경우
            changedX = Int(drawingContainer.frame.width - self.frame.width/2 + transition.x)
        }

        if leftY < 0 { // 상단으로 넘어가는 경우
            changedY = Int(self.frame.height/2 + transition.y)
        }
        else if rightY > drawingContainer.frame.height { // 하단으로 넘어가는 경우
            changedY = Int(drawingContainer.frame.height - self.frame.height/2 + transition.y)
        }
        
        print("drawing container size = \(drawingContainer.frame.width), \(drawingContainer.frame.height)")
        print("pan cahnged coordinate = \(changedX), \(changedY)")
        
        // begin(started) -> change(location) -> end(drop)
        switch panGestureRecognizer.state {
        case .began:
            print("pan begin")
            textAttribute.isDragging = true
                        
            textAttribute.isTextMoved = true
            
            textAttribute.setCoordinate(x: changedX, y: changedY)
            
            sendMqttMessage(textMode: .DRAG_STARTED)
            
            setLabelBorder(color: .orange)
            
        case .cancelled:
            print("pan cancel")
        case .changed:
            print("pan changed")
            
            textAttribute.setCoordinate(x: changedX, y: changedY)
            
            moveCounter += 1
            
            if moveCounter == MAX_MOVE {
                sendMqttMessage(textMode: .DRAG_LOCATION)
                moveCounter = -1
            }
            
            
        case .ended:
            print("pan ended") // DROP
            
            textAttribute.isDragging = false
            
            textAttribute.username = nil
            
            textAttribute.setCoordinate(x: changedX, y: changedY)
            
            sendMqttMessage(textMode: .DROP)
            
            setLabelBorder(color: .clear)

        case .failed:
            print("pan failed")
        case .possible:
            print("pan possible")
            
        }
        
        self.center = CGPoint(x: changedX, y: changedY)
        panGestureRecognizer.setTranslation(CGPoint.zero, in: self)
        
    }
    
    
    func setLabelBorder(color: UIColor) {
        self.layer.borderWidth = 1
        self.layer.borderColor = color.cgColor
    }
    
    
}

