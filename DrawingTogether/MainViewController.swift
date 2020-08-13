//
//  ViewController.swift
//  DrawingTogether
//
//  Created by trycatch on 2020/05/21.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit
import SVProgressHUD

class MainViewController: UIViewController {

//    @IBOutlet weak var ipTextField: UITextField!
//    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var topicErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var nameErrorLabel: UILabel!
    
    var masterName: String!
    var specialCharacterAndBlank: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGseture = UITapGestureRecognizer(target: self, action: #selector(dismissKeybord))
        view.addGestureRecognizer(tapGseture)
        
        SendMqttMessage.INSTANCE.startThread()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.isNavigationBarHidden = true // navigation bar 숨기기
    }
    
    @objc func dismissKeybord(tapGesture: UITapGestureRecognizer) {
//        ipTextField.resignFirstResponder()
//        portTextField.resignFirstResponder()
        topicTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
    }
    
    func hasSpecialCharacterAndBlank() {
        specialCharacterAndBlank = false
        
        if topicTextField.text!.isEmpty {
            topicErrorLabel.text = "빈칸을 채워주세요."
            specialCharacterAndBlank = true
        }
        
        if passwordTextField.text!.isEmpty {
            passwordErrorLabel.text = "빈칸을 채워주세요."
            specialCharacterAndBlank = true
        }
        
        if nameTextField.text!.isEmpty {
            nameErrorLabel.text = "빈칸을 채워주세요."
            specialCharacterAndBlank = true
        }
        
        if let topic = topicTextField.text {
            if topic.containsSpecialCharacter() {
                topicErrorLabel.text = "특수문자를 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
            if topic.containsWhitespace() {
                topicErrorLabel.text = "공백을 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
        }
        
        if let password = passwordTextField.text {
            if password.containsSpecialCharacter() {
                passwordErrorLabel.text = "특수문자를 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
            if password.containsWhitespace() {
                passwordErrorLabel.text = "공백을 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
        }
        
        if let name = nameTextField.text {
            if name.containsSpecialCharacter() {
                nameErrorLabel.text = "특수문자를 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
            if name.containsWhitespace() {
                nameErrorLabel.text = "공백을 포함하면 안됩니다."
                specialCharacterAndBlank = true
            }
        }
        
    }

    // 마스터 로그인 버튼
    @IBAction func onMasterLoginBtnClick(_ sender: UIButton) {
        topicErrorLabel.text = nil
        passwordErrorLabel.text = nil
        nameErrorLabel.text = nil
        
        hasSpecialCharacterAndBlank()
        
        if !specialCharacterAndBlank {
            
            let offset = UIOffset(horizontal: view.frame.width/2, vertical: view.frame.height/2)
            SVProgressHUD.setOffsetFromCenter(offset)
            SVProgressHUD.show()
            
            let accessDatabase = AccessDatabase()
            accessDatabase.connect()

            accessDatabase.runTransaction(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: true) {
                (masterName: String, topicError: Bool, passwordError: Bool, nameError: Bool) in
                //SVProgressHUD.dismiss()
                print("transaction completed")
                
                if topicError {
                    self.topicErrorLabel.text = "이미 존재하는 토픽입니다."
                }
                else {
                    self.masterName = masterName
                    self.performSegue(withIdentifier: "segueMasterLogin", sender: sender)
                    print("master login 클릭하여 drawing 화면으로 넘어감")
                }
            }
        }
    }
    
    // 조인 버튼
    @IBAction func onJoinBtnClick(_ sender: UIButton) {
        topicErrorLabel.text = nil
        passwordErrorLabel.text = nil
        nameErrorLabel.text = nil
        
        hasSpecialCharacterAndBlank()
        
        if !specialCharacterAndBlank {
            let offset = UIOffset(horizontal: view.frame.width/2, vertical: view.frame.height/2)
            SVProgressHUD.setOffsetFromCenter(offset)
            SVProgressHUD.show()
            
            let accessDatabase = AccessDatabase()
            accessDatabase.connect()
            
            accessDatabase.runTransaction(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: false) {
                (masterName: String, topicError: Bool, passwordError: Bool, nameError: Bool) in
                //SVProgressHUD.dismiss()
                print("transaction completed")
                
                if passwordError {
                    self.passwordErrorLabel.text = "비밀번호가 일치하지 않습니다."
                    return
                }
                if nameError {
                    self.nameErrorLabel.text = "이미 사용중인 이름입니다."
                    return
                }
                if topicError {
                    self.masterName = masterName
                    self.performSegue(withIdentifier: "segueJoin", sender: sender)
                    print("join 클릭하여 drawing 화면으로 넘어감")
                }
                else {
                    self.topicErrorLabel.text = "존재하지 않는 토픽입니다."
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // DrawingViewController의 ip, port, topic, name 값 세팅
        let drawingViewController = segue.destination as! DrawingViewController
//        drawingViewController.ip = ipTextField.text!
//        drawingViewController.port = portTextField.text!
        drawingViewController.topic = topicTextField.text!
        drawingViewController.name = nameTextField.text!
        drawingViewController.masterName = self.masterName
        
        if segue.identifier == "segueMasterLogin" {
            drawingViewController.master = true
        } else {
            drawingViewController.master = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        topicTextField.text = nil
        passwordTextField.text = nil
        nameTextField.text = nil
        
        topicErrorLabel.text = nil
        passwordErrorLabel.text = nil
        nameErrorLabel.text = nil
    }
    
}

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 8.0
    @IBInspectable var bottomInset: CGFloat = 8.0
    @IBInspectable var leftInset: CGFloat = 8.0
    @IBInspectable var rightInset: CGFloat = 8.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
}

extension String {
    
    func containsSpecialCharacter() -> Bool {
        let regex = try! NSRegularExpression(pattern: ".*[^0-9a-zA-Zㄱ-ㅎㅏ-ㅣ가-힁].*", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil
    }
    
    func containsWhitespace() -> Bool {
        return rangeOfCharacter(from: .whitespaces) != nil
    }
    
}
