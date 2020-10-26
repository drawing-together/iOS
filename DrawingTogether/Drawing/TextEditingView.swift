//
//  TextEditingView.swift
//  DrawingTogether
//
//  Created by 권나연 on 2020/06/10.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class TextEditingView: UIView {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var sizeBar: UISlider!
    
    var de: DrawingEditor = DrawingEditor.INSTANCE
    
    var drawingVC: DrawingViewController!

    var placeholder: String = "텍스트를 입력해주세요"
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
        
        print("init 1")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
        
        print("init 2")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        print("text editing view is drawn")
        
        if let text = de.currentText {
            sizeBar.value = (Float)(text.textAttribute.textSize!)
        }
        
        textView.becomeFirstResponder()
    }
    
    func initialize(){
        let view = Bundle.main.loadNibNamed(NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!, owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
                
        self.textView.delegate = de.drawingVC!
    }
    
    @IBAction func clickDone(_ sender: UIButton) {
        print("done")
        
        // 현재 편집중인 텍스트가 새로 생성하는 텍스트가 아니라, 생성된 후 편집하는 텍스트인 경우 done 버튼 클릭 가능 (username == null 로 세팅하기 위해)
        // 텍스트를 새로 생성하는 경우에 아직 다른 참가자들에게 텍스트 정보가 없기 때문에, 중간 참여자 접속을 기다린 후 생성 가능하도록 처리
        if de.isMidEntered, let text = de.currentText, !text.textAttribute.isTextInited {
            if let text = de.currentText, !text.textAttribute.isTextInited {
                drawingVC.showToast(message: "다른 참가자가 접속 중 입니다 잠시만 기다려주세요")
                return
            }
        }
        
//        if de.isMidEntered {
//            if let text = de.currentText, !text.textAttribute.isTextInited {
//                drawingVC.showToast(message: "다른 참가자가 접속 중 입니다 잠시만 기다려주세요")
//                return
//            }
//        }
        
            
        if let text = de.currentText {
            text.changeTextViewToLabel()
        }
        

        drawingVC.preMenuButton = drawingVC.preMenuButton ?? drawingVC.pencilBtn
        drawingVC.changeClickedButtonBackground(drawingVC.preMenuButton!)
        
        if drawingVC.preMenuButton == drawingVC.pencilBtn { // 도형은 펜 종류 지원 X, pencil 버튼인 경우만 펜 종류 표시
            drawingVC.penModeView.isHidden = false
        }

    }
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
    
        
//        let value: Int = (Int)(slider.value) / 10 * 10
        
        // text size only 10, 20, 30
        if (Int)(slider.value) % 10 == 0 {
            if let text = de.currentText {
                text.textAttribute.textSize = Int(slider.value)
                text.setTextViewAttribute()
            }
        }
        
        
    }
    
    
}

extension DrawingViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("text view did begin editing")
        
        if textView.text == textEditingView.placeholder {
            textView.text = ""
            textView.textColor = UIColor.black
        }
        if textView.text == "" {
            textView.text = textEditingView.placeholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) { // 포커스가 사라지면 호출 ( "Done" btn click )
        print("text view did end editing")
        
        textView.text = ""
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let MAX_LENGTH: Int = 30
        
        if let text = de.currentText {
            textView.textColor = UIColor(hexString: text.textAttribute.textColor!)
        }
        
        if textView.text == textEditingView.placeholder {
            textView.text = ""
        }
        
        if text == "\n" {
            textEditingView.clickDone(textEditingView.doneButton)
        }
        
        de.currentText?.textAttribute.text = textView.text
                
        return textView.text.count + (text.count - range.length) <= MAX_LENGTH
        
    }
    
}
