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

    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var ipErrorLabel: UILabel!
    @IBOutlet weak var portErrorLabel: UILabel!
    @IBOutlet weak var topicErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var nameErrorLabel: UILabel!
    
    var masterName: String!
    var specialCharacterAndBlank: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ipTextField.text = "54.180.154.63" // 클라우드
//        ipTextField.text = "192.168.0.36" // 모니터링
        portTextField.text = "1883"
        
        let tapGseture = UITapGestureRecognizer(target: self, action: #selector(dismissKeybord))
        view.addGestureRecognizer(tapGseture)
        
        SendMqttMessage.INSTANCE.startThread()
        
        // kakao params setting
        let app = UIApplication.shared.delegate as! AppDelegate
        if let kakaoTopic = app.appTopic, let kakaoPassword = app.appPassword {
            setKakaoTopic(topic: kakaoTopic)
            setKakaoPassword(password: kakaoPassword)
        }
        
        let scene =  UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
        if let kakaoTopic = scene.sceneTopic, let kakaoPassword = scene.scenePassword {
            setKakaoTopic(topic: kakaoTopic)
            setKakaoPassword(password: kakaoPassword)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.isNavigationBarHidden = true // navigation bar 숨기기
    }
    
    @objc func dismissKeybord(tapGesture: UITapGestureRecognizer) {
        ipTextField.resignFirstResponder()
        portTextField.resignFirstResponder()
        topicTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
    }
    
    func setKakaoTopic(topic: String) {
        let topViewController = navigationController?.topViewController
        if topViewController == self {
            topicTextField.text = topic
        }
    }
    
    func setKakaoPassword(password: String) {
        let topViewController = navigationController?.topViewController
        if topViewController == self {
            passwordTextField.text = password
        }
    }
    
    func hasSpecialCharacterAndBlank() {
        specialCharacterAndBlank = false
        
        if ipTextField.text!.isEmpty {
            ipErrorLabel.text = "아이피 주소를 입력해주세요."
            specialCharacterAndBlank = true
        }
        
        if portTextField.text!.isEmpty {
            portErrorLabel.text = "포트 번호를 입력해주세요."
            specialCharacterAndBlank = true
        }
        
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
            
            let alertController = UIAlertController(title: "마스터 체크", message: "마스터가 맞습니까?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "YES", style: .destructive) {
                (action) in
                self.afterMasterCheck(sender);
            }
            alertController.addAction(yesAction)
            alertController.addAction(UIAlertAction(title: "NO", style: .cancel))
            present(alertController, animated: true)
            
        }
    }
    
    func afterMasterCheck(_ sender: UIButton) {
        
        // network checking ...
        
        let offset = UIOffset(horizontal: view.frame.width/2, vertical: view.frame.height/2)
        SVProgressHUD.setOffsetFromCenter(offset)
        SVProgressHUD.show()
        
        let dt = DatabaseTransaction()
        dt.connect()

        dt.runTransactionLogin(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: true) {
            (errorMsg, masterName, topicError, passwordError, nameError) in
//            SVProgressHUD.dismiss()
            print("transaction completed")
            
            if !errorMsg.isEmpty {
                SVProgressHUD.dismiss()
                self.showDatabaseErrorAlert(title: "데이터베이스 오류 발생", message: errorMsg)
                return
            }
            if topicError {
                SVProgressHUD.dismiss()
                self.topicErrorLabel.text = "이미 존재하는 회의명입니다."
            }
            else {
                self.masterName = masterName
                self.performSegue(withIdentifier: "segueMasterLogin", sender: sender)
                print("master login 클릭하여 drawing 화면으로 넘어감")
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
            
            // network checking ...
            
            let offset = UIOffset(horizontal: view.frame.width/2, vertical: view.frame.height/2)
            SVProgressHUD.setOffsetFromCenter(offset)
            SVProgressHUD.show()
            
            let dt = DatabaseTransaction()
            dt.connect()
            
            dt.runTransactionLogin(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: false) {
                (errorMsg, masterName, topicError, passwordError, nameError) in
//                SVProgressHUD.dismiss()
                print("transaction completed")
                
                if !errorMsg.isEmpty {
                    SVProgressHUD.dismiss()
                    self.showDatabaseErrorAlert(title: "데이터베이스 오류 발생", message: errorMsg)
                    return
                }
                if passwordError {
                    SVProgressHUD.dismiss()
                    self.passwordErrorLabel.text = "비밀번호가 일치하지 않습니다."
                    return
                }
                if nameError {
                    SVProgressHUD.dismiss()
                    self.nameErrorLabel.text = "이미 사용중인 이름입니다."
                    return
                }
                if topicError {
                    self.masterName = masterName
                    self.performSegue(withIdentifier: "segueJoin", sender: sender)
                    print("join 클릭하여 drawing 화면으로 넘어감")
                }
                else {
                    SVProgressHUD.dismiss()
                    self.topicErrorLabel.text = "존재하지 않는 회의명입니다."
                }
            }
        }
    }
    
    func showDatabaseErrorAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "YES", style: .destructive))
        present(alertController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // DrawingViewController의 ip, port, topic, name 값 세팅
        let drawingViewController = segue.destination as! DrawingViewController
        drawingViewController.ip = ipTextField.text!
        drawingViewController.port = portTextField.text!
        drawingViewController.topic = topicTextField.text!
        drawingViewController.password = passwordTextField.text!
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

extension String {
    
    func containsSpecialCharacter() -> Bool {
        let regex = try! NSRegularExpression(pattern: ".*[^0-9a-zA-Zㄱ-ㅎㅏ-ㅣ가-힁].*", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil
    }
    
    func containsWhitespace() -> Bool {
        return rangeOfCharacter(from: .whitespaces) != nil
    }
    
}
