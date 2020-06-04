//
//  DrawingViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/05/25.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {
    
    let client = MQTTClient.client
    
    @IBOutlet weak var userNumLabel: PaddingLabel!
    @IBOutlet weak var namesPrintLabel: PaddingLabel!
    
    var ip: String!
    var port: String!
    var topic: String!
    var name: String!
    var masterName: String!
    var master: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DrawingViewController : viewDidLoad")
        
        client.initialize(ip, port, topic, name, master, masterName, self)
        print("DrawingViewController : [topic = \(topic!), my name = \(name!), master = \(master!)]")
    }
    
    func setUserNum(userNum: Int) {
        userNumLabel.text = "현재인원 : \(userNum)명"
    }
    
    func setNamesPrint(names: String) {
        namesPrintLabel.text = names
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
        setNamesPrint(names: "")
        client.exitTask()
        client.unsubscribeAllTopics()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        print("DrawingViewController : viewDidDisappear")
    }
    
    @IBAction func clickMic(_ sender: UIBarButtonItem) {
        print("mic")
        client.publish(topic: "\(topic!)_join", message: "topic join !!!")
    }
    
    @IBAction func clickSpeaker(_ sender: UIBarButtonItem) {
        print("speaker")
        client.subscribe("test")
    }
    
    @IBAction func clickImage(_ sender: UIBarButtonItem) {
        print("image")
        client.unsubscribe("test")
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
}

