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
        
        de.currentMode = .TEXT
        
       if let text = de.currentText {
            text.changeTextViewToLabel()
        }
        
        self.removeFromSuperview()
    }
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
    
        let value = slider.value / 10 * 10
        
        if let text = de.currentText {
            text.textAttribute.textSize = Int(value)
            text.setTextViewAttribute()
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
        let MAX_LENGTH: Int = 40
        
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
