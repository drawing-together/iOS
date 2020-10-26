//
//  DrawingViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/05/25.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import SVProgressHUD

class DrawingViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    let de = DrawingEditor.INSTANCE
    let client = MQTTClient.client
    let parser = JSONParser.parser
    
    @IBOutlet weak var userNumBtn: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var drawingView: DrawingView!
    @IBOutlet weak var currentView: UIImageView!
    @IBOutlet weak var myCurrentView: UIImageView!
    
    @IBOutlet weak var drawingContainer: UIView!
    @IBOutlet weak var currentColorBtn: UIButton!
    @IBOutlet weak var penModeView: UIStackView!
    @IBOutlet weak var drawingTools: UIStackView!
    @IBOutlet weak var textColorChangeBtn: UIButton!
    @IBOutlet weak var colorChangeBtnView: UIView!
    
    @IBOutlet weak var pencilBtn: UIButton!
    @IBOutlet weak var highlightBtn: UIButton!
    @IBOutlet weak var neonBtn: UIButton!
    
    @IBOutlet weak var undoBtn: UIButton!
    @IBOutlet weak var redoBtn: UIButton!
    
    var textEditingView: TextEditingView!
    
    var ip: String = "54.180.154.63"
    var port: String = "1883"
    var topic: String!
    var password: String!
    var name: String!
    var masterName: String!
    var master: Bool!
    
    var userListStr: String!
    var userVC: UserViewController!
    
    var closeFlag: Bool = false
    
    // AUDIO
    var micFlag = false
    var speakerFlag = false
    var speakerMode = 0 // 0: mute, 1: on, 2: loud
    //
      
    // IMAGE
    var imagePicker = UIImagePickerController()
    var cameraFlag = false
    //
    
    var shapeVC: ShapeViewController!
    var eraserVC: EraserViewController!
    var penVC: PenViewController!
    
    let src_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    let dst_triangle = UnsafeMutablePointer<Int32>.allocate(capacity: 2)
    var src: [Int32] = [], dst: [Int32] = []
    var src2: [Int32] = [], dst2: [Int32] = []
    var warpImg: UIImage?
    
    var preMenuButton: UIButton? // 드로잉 메뉴 버튼 (펜, 도형) 저장, 텍스트에서 기본 드로잉모드로 돌아가기 위해 -
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DrawingViewController : viewDidLoad")
        
        UIApplication.shared.isIdleTimerDisabled = true // 화면 안꺼지게
        
        parser.drawingVC = self
        
        userVC = storyboard?.instantiateViewController(withIdentifier: "UserViewController") as? UserViewController
        shapeVC = storyboard?.instantiateViewController(withIdentifier: "ShapeViewController") as? ShapeViewController
        eraserVC = storyboard?.instantiateViewController(withIdentifier: "EraserViewController") as? EraserViewController
        penVC = storyboard?.instantiateViewController(withIdentifier: "PenViewController") as? PenViewController
        
        client.initialize(ip, port, topic, name, master, masterName, self)
        closeFlag = false
        print("DrawingViewController : [topic = \(topic!), my name = \(name!), master = \(master!)]")
        
        imagePicker.delegate = self
        
        navigationController?.isNavigationBarHidden = false
        
        //let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(drawingTapped))
        //drawingView.addGestureRecognizer(tapGestureRecognizer)
        drawingView.isUserInteractionEnabled = true
        de.initialize(drawingVC: self, master: master)
        
        if de.history.count == 0 { self.setUndoEnabled(isEnabled: false) }
        if de.undoArray.count == 0 { self.setRedoEnabled(isEnabled: false) }
        
        // Text Editing View Setup
        print("drawing container size = \(drawingContainer.frame.width), \(drawingContainer.frame.height)")
        textEditingView = TextEditingView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)) // call initialize()
        textEditingView.textView.delegate = self
        textEditingView.drawingVC = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("DrawingViewController : viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("DrawingViewController : viewDidAppear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("DrawingViewController : viewWillDisappear")
        
        if cameraFlag {
            return
        }
        
        setUserNum(userNum: 0)
        userListStr = ""
        
        if (!closeFlag) {
            client.exitTask()
            client.unsubscribeAllTopics()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        print("DrawingViewController : viewDidDisappear")
        
        client.session?.disconnect()
    }
    
    // MARK: FUNCTION
    func showAlert(title: String, message: String, selectable: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "확인", style: .destructive) {
            (action) in
            
            let offset = UIOffset(horizontal: self.view.frame.width/2, vertical: self.view.frame.height/2)
            SVProgressHUD.setOffsetFromCenter(offset)
            SVProgressHUD.show()
            
            // network checking ...
            
            // database delete
            let dt = DatabaseTransaction()
            dt.connect()
            dt.runTranscationExit(topic: self.topic!, name: self.name!, masterMode: self.master!) {
                (errorMsg) in
                SVProgressHUD.dismiss()
                if !errorMsg.isEmpty {
                    self.showDatabaseErrorAlert(title: "데이터베이스 오류 발생", message: errorMsg)
                    return
                }
                // mqtt connection check ...
                
                // exit task
                self.client.exitTask()
                self.client.unsubscribeAllTopics()
                self.closeFlag = true
                
                // move to home
                if let topViewController = self.navigationController?.viewControllers.first {
                    self.navigationController?.popToViewController(topViewController, animated: true)
                }
            }
        }
        alertController.addAction(yesAction)
        
        
        let saveAction = UIAlertAction(title: "저장 후 종료", style: .default) {
            (action) in
            
            let offset = UIOffset(horizontal: self.view.frame.width/2, vertical: self.view.frame.height/2)
            SVProgressHUD.setOffsetFromCenter(offset)
            SVProgressHUD.show()

            
            UIImageWriteToSavedPhotosAlbum(self.drawingContainer.capture().image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            // database delete
            let dt = DatabaseTransaction()
            dt.connect()
            dt.runTranscationExit(topic: self.topic!, name: self.name!, masterMode: self.master!) {
                (errorMsg) in
                SVProgressHUD.dismiss()
                if !errorMsg.isEmpty {
                    self.showDatabaseErrorAlert(title: "데이터베이스 오류 발생", message: errorMsg)
                    return
                }
                // mqtt connection check ...
                
                // exit task
                self.client.exitTask()
                self.client.unsubscribeAllTopics()
                self.closeFlag = true
                
                // move to home
                if let topViewController = self.navigationController?.viewControllers.first {
                    self.navigationController?.popToViewController(topViewController, animated: true)
                }
            }
            
            

        }
        alertController.addAction(saveAction)
        
        
        if selectable {
            alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        }
        present(alertController, animated: true)
    }
    
    func showDatabaseErrorAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .destructive))
        present(alertController, animated: true)
    }
    
    // popover 띄우기 위한 함수
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func setUserNum(userNum: Int) {
        userNumBtn.setTitle("현재 인원 : \(userNum)명", for: .normal)
    }
    
    // UIBarButtonItem -> iPad 위치 지정 필요
    func setLocationAlert(sender: UIBarButtonItem, alertController: UIAlertController) {
        if UIDevice.current.userInterfaceIdiom == .pad {  // 디바이스 타입이 iPad일 때
            if let popoverController = alertController.popoverPresentationController {
                // set alert sheet location
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                
                popoverController.barButtonItem = sender
                present(alertController, animated: true, completion: nil)
            }
        }
        else {
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func changeClickedButtonBackground(_ button: UIButton) {
        
        for view in drawingTools.arrangedSubviews {
            view.backgroundColor = UIColor.clear
        }
        button.backgroundColor = UIColor(red: 233/255, green: 233/255, blue: 233/255, alpha: 1.0)
    }
    
    // MARK: IBACTION FUNCION
    @IBAction func backPressed(sender: UIBarButtonItem) {
        print("back pressed")
        var title = "회의방 종료"
        var message = "회의방을 종료하시겠습니까?"
        if !master {
            title = "회의방 나가기"
            message = "회의방을 나가시겠습니까?"
        }
        showAlert(title: title, message: message, selectable: true)
    }
    
    @IBAction func clickMic(_ sender: UIBarButtonItem) {
        if !micFlag { // Mic On
            micFlag = true
            sender.image = UIImage(systemName: "mic")
        } else { // Mic Off
            micFlag = false
            sender.image = UIImage(systemName: "mic.slash")
        }
    }
    
    @IBAction func clickSpeaker(_ sender: UIBarButtonItem) {
        speakerMode = (speakerMode + 1) % 3
        
        if speakerMode == 0 { // Speaker Mute
            speakerFlag = false
            sender.image = UIImage(systemName: "speaker.slash")
        } else if speakerMode == 1 { // Speaker On
            speakerFlag = true
            sender.image = UIImage(systemName: "speaker.1")
            client.subscribe("\(topic!)_audio")
        } else if speakerMode == 2 { // Speaker Loud
            sender.image = UIImage(systemName: "speaker.3")
        }
    }
    
    @IBAction func clickImage(_ sender: UIBarButtonItem) {
        let alert = UIAlertController()
        // Gallery
        let galleryAction = UIAlertAction(title: "갤러리", style: .default) {
            action in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: false, completion: nil)
        }
        // Camera
        let cameraAction = UIAlertAction(title: "카메라", style: .default) {
            action in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.cameraFlag = true
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: false, completion: nil)
            } else {
                print("Camera not available")
            }
        }

        alert.addAction(galleryAction)
        alert.addAction(cameraAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))

        setLocationAlert(sender: sender, alertController: alert)
        //        present(alert, animated: true, completion: nil)

    }
    
    @IBAction func clickMore(_ sender: UIBarButtonItem) {
        let alert = UIAlertController()
        // Save Image
        let saveImageAction = UIAlertAction(title: "저장하기", style: .default) {
            action in
            print("저장하기")
            
            UIImageWriteToSavedPhotosAlbum(self.drawingContainer.capture().image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        // Plus Person
        let plusPersonAction = UIAlertAction(title: "친구 초대", style: .default) {
            action in
            print("친구 초대")
            
            // 카카오톡 링크 보내기
            let template = KMTTextTemplate { (textTemplateBuilder) in
                
                // text
                textTemplateBuilder.text = "시시콜콜! 들어와!"
                // link
                textTemplateBuilder.link = KMTLinkObject(builderBlock: { (linkBuilder) in
                    
                    linkBuilder.iosExecutionParams = "topic=\(self.topic!)&password=\(self.password!)"
                    linkBuilder.androidExecutionParams = "topic=\(self.topic!)&password=\(self.password!)"
                    
                })
                // button
                textTemplateBuilder.buttonTitle = "앱으로 이동!"
            }
            
            KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
                            
                // success
                print("warning message: \(String(describing: warningMsg))")
                print("argument message: \(String(describing: argumentMsg))")
                
            }, failure: {(error) in
                
                // failure
                print("error: \(error)")
            })
        }
        alert.addAction(saveImageAction)
        alert.addAction(plusPersonAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                
        setLocationAlert(sender: sender, alertController: alert)
        //        present(alert, animated: true, completion: nil)
            
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            // we got back an error!
//            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default))
//            present(ac, animated: true)
            showToast(message: "이미지 저장 오류")
        } else {
//            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default))
//            present(ac, animated: true)
            showToast(message: "갤러리에 대화 이미지를 저장 완료했습니다")
        }
    }

    @IBAction func clickUndo(_ sender: UIButton) {
        print("undo")
        drawingView!.undo()
    }
    
    @IBAction func clickRedo(_ sender: UIButton) {
        print("redo")
        drawingView!.redo()
    }
    
    @IBAction func clickPen(_ sender: UIButton) {
        print("pen")
        penModeView.isHidden = false
        changeClickedButtonBackground(sender)
        
        if de.currentMode == Mode.DRAW && de.currentType == ComponentType.STROKE {
            penVC.modalPresentationStyle = .popover
            penVC.preferredContentSize = CGSize(width: 110, height: 120)
            if let popoverController = penVC.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = CGRect(x: -23, y: -5, width: 100, height: 35)
                popoverController.permittedArrowDirections = .any
                popoverController.delegate = self
                penVC.popoverPresentationController?.delegate = self
            }
            
            present(penVC, animated: true, completion: nil)
        }
        
        de.currentMode = Mode.DRAW
        de.currentType = ComponentType.STROKE
        //de.penMode = PenMode.NORMAL
        
        preMenuButton = sender // 텍스트 편집 후 기본 모드인 드로잉 메뉴 배경색 변경을 위해
    }
    
    @IBAction func clickPencil(_ sender: UIButton) {
        pencilBtn.setImage(UIImage(named:"pencil_1.png"), for: .normal)
        highlightBtn.setImage(UIImage(named:"highlight_0.png"), for: .normal)
        neonBtn.setImage(UIImage(named:"neon_0.png"), for: .normal)
        
        de.penMode = PenMode.NORMAL
    }
    
    @IBAction func clickHighlight(_ sender: UIButton) {
        pencilBtn.setImage(UIImage(named:"pencil_0.png"), for: .normal)
        highlightBtn.setImage(UIImage(named:"highlight_1.png"), for: .normal)
        neonBtn.setImage(UIImage(named:"neon_0.png"), for: .normal)
        
        de.penMode = PenMode.HIGHLIGHT
    }
    
    @IBAction func clickNeon(_ sender: UIButton) {
        pencilBtn.setImage(UIImage(named:"pencil_0.png"), for: .normal)
        highlightBtn.setImage(UIImage(named:"highlight_0.png"), for: .normal)
        neonBtn.setImage(UIImage(named:"neon_1.png"), for: .normal)
        
        de.penMode = PenMode.NEON
    }
    
    @IBAction func clickShape(_ sender: UIButton) {
        print("shape")
        penModeView.isHidden = true
        changeClickedButtonBackground(sender)

        shapeVC.modalPresentationStyle = .popover
        shapeVC.preferredContentSize = CGSize(width: 110, height: 120)
        if let popoverController = shapeVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: -32, y: -5, width: 100, height: 35)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
            shapeVC.popoverPresentationController?.delegate = self
        }
        
        present(shapeVC, animated: true, completion: nil)
        
        preMenuButton = sender // 텍스트 편집 후 기본 모드인 드로잉으로 돌아가기 위해 (텍스트 편집 전에 선택했던 드로잉 모드로)

    }
    
    @IBAction func clickText(_ sender: UIButton) {
        print("text")
        penModeView.isHidden = true
        changeClickedButtonBackground(sender)
        
        /* 사용자가 처음 텍스트 편집창에서 텍스트 생성중인 경우 */
        /* 텍스트 정보들을 모든 사용자가 갖고 있지 않음 ( 편집중인 사람만 갖고 있음 ) */
        /* 따라서 중간자가 들어오고 난 후에 텍스트 생성을 할 수 있도록 막아두기 */
        
        if de.isMidEntered {
            showToast(message: "다른 사용자가 접속 중 입니다 잠시만 기다려주세요")
            return
        }
        
        de.currentMode = .TEXT
        
        let text = Text()
        let textAttr = TextAttribute(id: de.setTextStringId(), username: de.myUsername!, textSize: de.textSize, textColor: de.textColor, generatedLayoutWidth: Int(drawingContainer.frame.width), generatedLayoutHeight: Int(drawingContainer.frame.height))
        
        text.create(textAttribute: textAttr, drawingVC: self)
        text.changeLabelToTextView()
        
        
//        let text: UILabel = UILabel()
//        text.frame.size.width = drawingContainer.frame.width/3
//
//        text.text = "aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeee"
//        text.backgroundColor = UIColor.clear
//        text.textColor = UIColor(hexString: "#000000")
//        text.font = UIFont.boldSystemFont(ofSize: (CGFloat)(20))
//        text.textAlignment = .center
//
//        text.lineBreakMode = .byWordWrapping
//        text.numberOfLines = 0
//
//        text.sizeToFit()
//
//        text.frame = CGRect(x: 100, y: 100, width: text.frame.width, height: text.frame.height)
//
//        drawingContainer.addSubview(text)
    }
    
    @IBAction func clickEraser(_ sender: UIButton) {
        print("eraser")
        penModeView.isHidden = true
        changeClickedButtonBackground(sender)
        
        if de.currentMode == Mode.ERASE {
            eraserVC.modalPresentationStyle = .popover
            eraserVC.preferredContentSize = CGSize(width: 110, height: 120)
            if let popoverController = eraserVC.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = CGRect(x: -32, y: -5, width: 100, height: 35)
                popoverController.permittedArrowDirections = .any
                popoverController.delegate = self
                eraserVC.popoverPresentationController?.delegate = self
            }
            
            present(eraserVC, animated: true, completion: nil)
        }
        
        de.currentMode = .ERASE
    }
    
    @IBAction func clickSelector(_ sender: UIButton) {
        print("selector")
        penModeView.isHidden = true
        changeClickedButtonBackground(sender)
        
        de.currentMode = Mode.SELECT
    }
    
    @IBAction func clickWarping(_ sender: UIButton) {
        print("warping")
        penModeView.isHidden = true
        changeClickedButtonBackground(sender)
        
        de.currentMode = Mode.WARP
    }
    
    @IBAction func clickUserBtn(_ sender: UIButton) {
        userVC.modalPresentationStyle = .popover
        userVC.preferredContentSize = CGSize(width: 100, height: 150)
        if let popoverController = userVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 5, y: 0, width: 100, height: 35)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
            userVC.popoverPresentationController?.delegate = self
        }
        
        present(userVC, animated: true, completion: nil)
        
        userVC.userLabel.text! = userListStr
    }
    
    @IBAction func clickColor(_ btn: UIButton) {
        
        currentColorBtn.backgroundColor = btn.backgroundColor
        
        switch de.currentMode {
        case .DRAW, .ERASE, .SELECT:
        
            de.strokeColor = btn.backgroundColor?.toHexString()
            de.fillColor = btn.backgroundColor?.toHexString()
            break
        
        case .TEXT :
            if let text = de.currentText {
                text.textAttribute.textColor = btn.backgroundColor?.toHexString()
                text.setLabelAttribute()
            }
            break
            
        case .none:
            break
        case .some(_):
            break
        }
    }
    
    
    @IBAction func clickTextColorChange(_ btn: UIButton) {
        if let text = de.currentText {
            text.finishTextColorChange()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var xList: [Int] = []
        var yList: [Int] = []
        src = []
        dst = []
        let size = CGSize(width:  self.backgroundImageView.frame.width  , height: self.backgroundImageView.frame.height )
        for touch in touches {
            let startPoint = touch.location(in: self.backgroundImageView)
            let x = Int32(startPoint.x)
            let y = Int32(startPoint.y)
            if x > Int(size.width) || y > Int(size.height) {
                return
            }
            xList.append(Int(x))
            yList.append(Int(y))
            src.append(x)
            src.append(y)
            print(src)
        }
        if let image = self.backgroundImageView.image {
            warpImg = image
        }
        src_triangle.initialize(from: &src, count: 4)
        print(src_triangle)
        
        let message = MqttMessageFormat(username: de.myUsername!, mode: .WARP, type: de.currentType!, action: 0, warpingMessage: WarpingMessage(action: 0, pointerCount: touches.count/2, x: xList, y: yList, width: Int(size.width), height: Int(size.height)))
        client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
        
//        if let theTouch = touches.first {
//            let startPoint = theTouch.location(in: self.backgroundImageView)
//            let x = Int32(startPoint.x)
//            let y = Int32(startPoint.y)
//            src = [x, y]
////            print(src)
//            if let image = self.backgroundImageView.image {
//                warpImg = image
//            }
//            src_triangle.initialize(from: &src, count: 2)
//            let message = MqttMessageFormat(username: de.myUsername!, mode: .WARP, type: de.currentType!, action: 0, warpingMessage: WarpingMessage(action: 0, pointerCount: 1, x: [Int(x)], y: [Int(y)]))
//            client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
//        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        var xList: [Int] = []
        var yList: [Int] = []
        dst = []
        let size = CGSize(width:  self.backgroundImageView.frame.width  , height: self.backgroundImageView.frame.height )
        for touch in touches {
            let movePoint = touch.location(in: self.backgroundImageView)
            let x = Int32(movePoint.x)
            let y = Int32(movePoint.y)
            if x > Int(size.width) || y > Int(size.height) {
                return
            }
            xList.append(Int(x))
            yList.append(Int(y))
            dst.append(x)
            dst.append(y)
            print(dst)
        }
        dst_triangle.initialize(from: &dst, count: 4)
        
        let message = MqttMessageFormat(username: de.myUsername!, mode: .WARP, type: de.currentType!, action: 0, warpingMessage: WarpingMessage(action: 2, pointerCount: xList.count, x: xList, y: yList, width: Int(size.width), height: Int(size.height)))
       client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
        
//        if let theTouch = touches.first {
//            let movePoint = theTouch.location(in: self.view)
//            let x = Int32(movePoint.x)
//            let y = Int32(movePoint.y)
//            dst = [x, y]
//
////            print(movePoint)
//            print("=========")
//            dst_triangle.initialize(from: &dst, count: 2)
//            let message = MqttMessageFormat(username: de.myUsername!, mode: .WARP, type: de.currentType!, action: 0, warpingMessage: WarpingMessage(action: 2, pointerCount: 1, x: [Int(x)], y: [Int(y)]))
//            client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
//        }
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if let image = warpImg {
            self.backgroundImageView.image = OpenCVWrapper.cvWarp(image, w:  Int32(rect.width)  , h: Int32(rect.height), src: self.src_triangle, dst: self.dst_triangle)
        }
        self.src = self.dst
        
    }
    
    func warp(warpData: WarpData, width: Int, height: Int) {
        DispatchQueue.main.async {
            if warpData.action == 0 {
                self.src = []
                self.dst = []
                let size = CGSize(width:  self.backgroundImageView.frame.width  , height: self.backgroundImageView.frame.height )
                for point in warpData.points {
                    self.src.append(Int32(point.x * Int(size.width) / width))
                    self.src.append(Int32(point.y * Int(size.height) / height))
                }
                if let image = self.backgroundImageView.image {
                    self.warpImg = image
                }
                self.src_triangle.initialize(from: &self.src, count: 4)
                
            }
            else if warpData.action == 2 {
                self.dst = []
                let size = CGSize(width:  self.backgroundImageView.frame.width  , height: self.backgroundImageView.frame.height )
                let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                for point in warpData.points {
                    self.dst.append(Int32(point.x * Int(size.width) / width))
                    self.dst.append(Int32(point.y * Int(size.height) / height))
                }
                print(self.dst)
                self.dst_triangle.initialize(from: &self.dst, count: 4)
                if let image = self.warpImg {
                    self.backgroundImageView.image = OpenCVWrapper.cvWarp(image, w:  Int32(rect.width)  , h: Int32(rect.height), src: self.src_triangle, dst: self.dst_triangle)
                }
                self.src = self.dst
            }
        }
    }
    
    func setRedoEnabled(isEnabled: Bool) {
        //set image
        redoBtn.isEnabled = isEnabled
    }
    
    func setUndoEnabled(isEnabled: Bool) {
        //set image
        undoBtn.isEnabled = isEnabled
    }
    
    /*@objc func drawingTapped(_ tapGesture: UITapGestureRecognizer) {
        if de.currentMode != Mode.SELECT { return }
        
        if tapGesture.state == .ended {
            let touchLocation: CGPoint = tapGesture.location(in: tapGesture.view)
            drawingView.selectTapped(point: Point(x: Int(touchLocation.x), y: Int(touchLocation.y)))
            //print(touchLocation)
        }
        //print(tapGesture.location(in: tapGesture.view))
    }*/

}

extension DrawingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if cameraFlag {
            cameraFlag = false
        }
        
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
//        backgroundImageView.image = image
        
        de.backgroundImage = de.convertUIImage2ByteArray(image: image)
        client.publish(topic: client.topic_image, message: de.backgroundImage!)
        
//        let message = MqttMessageFormat(username: name!, mode: .BACKGROUND_IMAGE, bitmapByteArray: de.bitmapByteArray!)
//        client.publish(topic: client.topic_data, message: parser.jsonWrite(object: message)!)
        
        dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
    
    func showToast(message : String/*, font: UIFont*/) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height-150, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 12)
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 2.0, delay: 1.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension UIColor {
    convenience init(hexString:String) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
        }
        
        var color:UInt64 = 0
        scanner.scanHexInt64(&color)

        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask

        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0

        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}


@IBDesignable extension UIButton {
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

extension UIView {
    
    func capture(_ shadow: Bool = false) -> UIImageView {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapshotImageView = UIImageView(image: image)
        if shadow {
            snapshotImageView.layer.masksToBounds = false
            snapshotImageView.layer.cornerRadius = 0.0
            snapshotImageView.layer.shadowOffset = CGSize(width: -0.5, height: 0.0)
            snapshotImageView.layer.shadowRadius = 5.0
            snapshotImageView.layer.shadowOpacity = 0.4
        }
        
        return snapshotImageView
        
    }
    
}

