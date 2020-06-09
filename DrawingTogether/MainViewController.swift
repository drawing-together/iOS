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
    
    var masterName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGseture = UITapGestureRecognizer(target: self, action: #selector(dismissKeybord))
        view.addGestureRecognizer(tapGseture)
    }
    
    @objc func dismissKeybord(tapGesture: UITapGestureRecognizer) {
        ipTextField.resignFirstResponder()
        portTextField.resignFirstResponder()
        topicTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
    }
    
    @objc func isFilled() -> Bool {
        if topicTextField.text?.isEmpty ?? true || passwordTextField.text?.isEmpty ?? true || nameTextField.text?.isEmpty ?? true {
            print("not filled")
            return false
        }
        print("filled")
        return true
        
    }

    // 마스터 로그인 버튼
    @IBAction func onMasterLoginBtnClick(_ sender: UIButton) {
        if isFilled() {
            let accessDatabase = AccessDatabase()
            accessDatabase.connect()
            var isExistTopic = false
            
            accessDatabase.runTransaction(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: true) {
                (masterName: String, existTopic: Bool) in
                SVProgressHUD.dismiss()
                print("transaction completed")
                isExistTopic = existTopic
                
                if isExistTopic {
                    return
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
        if isFilled() {
            let accessDatabase = AccessDatabase()
            accessDatabase.connect()
            var isExistTopic = false
            
            accessDatabase.runTransaction(topic: topicTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, masterMode: false) {
                (masterName: String, existTopic: Bool) in
                SVProgressHUD.dismiss()
                print("transaction completed")
                isExistTopic = existTopic
                
                if isExistTopic {
                    self.masterName = masterName
                    self.performSegue(withIdentifier: "segueJoin", sender: sender)
                    print("join 클릭하여 drawing 화면으로 넘어감")
                }
                else {
                    return
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // DrawingViewController의 ip, port, topic, name 값 세팅
        let drawingViewController = segue.destination as! DrawingViewController
        drawingViewController.ip = ipTextField.text!
        drawingViewController.port = portTextField.text!
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
