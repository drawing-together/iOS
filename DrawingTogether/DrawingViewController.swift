//
//  DrawingViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/05/25.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    let de = DrawingEditor.INSTANCE
    let client = MQTTClient.client
    
    @IBOutlet weak var userNumBtn: UIButton!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var drawingView: DrawingView!
    
    @IBOutlet weak var textEditingView: TextEditingView!
    @IBOutlet weak var editingText: UITextField!
    
    var ip: String = "54.180.154.63"
    var port: String = "1883"
    var topic: String!
    var name: String!
    var masterName: String!
    var master: Bool!
    
    var userListStr: String!
    
    // AUDIO
    var micFlag = false
    var speakerFlag = false
    var speakerMode = 0 // 0: mute, 1: on, 2: loud
    //
      
    // IMAGE
    var imagePicker = UIImagePickerController()
    //
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DrawingViewController : viewDidLoad")
        
        client.initialize(ip, port, topic, name, master, masterName, self)
        print("DrawingViewController : [topic = \(topic!), my name = \(name!), master = \(master!)]")
        
        imagePicker.delegate = self
        
        navigationController?.isNavigationBarHidden = false
        
        drawingView.isUserInteractionEnabled = true
        de.initialize(drawingVC: self, drawingView: self.drawingView)
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
        
        setUserNum(userNum: 0)
        userListStr = ""
        client.exitTask()
        client.unsubscribeAllTopics()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        print("DrawingViewController : viewDidDisappear")
    }
    
    // MARK: FUNCTION
    func showAlert(title: String, message: String, selectable: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "YES", style: .destructive) {
            (action) in
            // exit task
            self.client.exitTask()
            self.client.unsubscribeAllTopics()
            // move to home
            if let topViewController = self.navigationController?.viewControllers.first {
                self.navigationController?.popToViewController(topViewController, animated: true)
            }
        }
        alertController.addAction(yesAction)
        if selectable {
            alertController.addAction(UIAlertAction(title: "NO", style: .cancel))

        }
        present(alertController, animated: true)
    }
    
    // popover 띄우기 위한 함수
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func setUserNum(userNum: Int) {
        userNumBtn.setTitle("현재인원 : \(userNum)명", for: .normal)
    }
    
    func convertUIImage2ByteArray(image: UIImage) -> [UInt8] { // UIImage -> Byte Array
        // UIImage -> NSData
        let imageData = image.jpegData(compressionQuality: 0.1)!
        // NSData의 길이 구하기
        let count = imageData.count / MemoryLayout<UInt8>.size
        print("IMAGE : byte array size = \(count)")
        // Byte Array 생성
        var imageByteArray = [UInt8](repeating: 0, count: count)
        // NSData -> Byte Array
        imageData.copyBytes(to: &imageByteArray, count: count)

        return imageByteArray
    }
    
    func convertByteArray2UIImage(byteArray: [UInt8]) -> UIImage { // Byte Array -> UIImage
        // Byte Array의 길이 구하기
        let count = byteArray.count
        // NSData 생성, Byte Array -> NSData
        let imageData: NSData = NSData(bytes: byteArray, length: count)
        // NSData -> UIImage
        let image: UIImage = UIImage(data: imageData as Data)!
        
        return image
    }
    
    // MARK: IBACTION FUNCION
    @IBAction func backPressed(sender: UIBarButtonItem) {
        print("back pressed")
        var title = "토픽 종료"
        var message = "토픽을 종료하시겠습니까?"
        if !master {
            title = "토픽방 나가기"
            message = "토픽방을 나가시겠습니까?"
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
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: false, completion: nil)
            } else {
                print("Camera not available")
            }
        }

        alert.addAction(galleryAction)
        alert.addAction(cameraAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    @IBAction func clickUndo(_ sender: UIButton) {
        print("undo")
    }
    
    @IBAction func clickRedo(_ sender: UIButton) {
        print("redo")
    }
    
    @IBAction func clickPen(_ sender: UIButton) {
        print("pen")
        print(sender.accessibilityIdentifier!) // 각 버튼의 Accessibility의 identifier 속성을 10, 20, 30으로 설정
        de.strokeWidth = CGFloat(NSString(string: sender.accessibilityIdentifier!).floatValue)
    }
    
    @IBAction func clickShape(_ sender: UIButton) {
        print("shape")
    }
    
    @IBAction func clickText(_ sender: UIButton) {
        print("text")
    }
    
    @IBAction func clickEraser(_ sender: UIButton) {
        print("eraser")
    }
    
    @IBAction func clickWarping(_ sender: UIButton) {
        print("warping")
    }
    
    @IBAction func clickUserBtn(_ sender: UIButton) {
        let userVC = storyboard?.instantiateViewController(withIdentifier: "UserViewController") as! UserViewController
        
        userVC.modalPresentationStyle = .popover
        userVC.preferredContentSize = CGSize(width: 100, height: 150)
        if let popoverController = userVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect =  CGRect(x: 0, y: 0, width: 100, height: 35)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
            userVC.popoverPresentationController?.delegate = self
        }
        
        present(userVC, animated: true, completion: nil)
        
        userVC.userLabel.text! = userListStr
    }
}

extension DrawingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,          didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        backgroundImageView.image = image
        
        //        let imageByte = convertUIImage2ByteArray(image: image
        //        let message = "{\"action\":0,\"bitmapByteArray\":\(imageByte),\"mode\":\"BACKGROUND_IMAGE\",\"myTextArrayIndex\":0,\"username\":\"jiyeon\"}"
        //        client.publish(topic: "\(topic!)_data", message: message)
        
        dismiss(animated: true, completion: nil)
    }
    
}

extension UIViewController {
    
    func showToast(message : String/*, font: UIFont*/) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-150, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        //toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
