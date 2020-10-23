//
//  InfoViewController.swift
//  DrawingTogether
//
//  Created by jiyeon on 2020/10/23.
//  Copyright © 2020 hansung. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let drawingTogetherColor = UIColor(hexString: "16A0E8")

        let messageString = "사용 방법 및 설명\n\nstep1 회의명, 비밀번호, 이름을 입력합니다.\n(카카오톡 초대 링크로 앱을 실행한 경우, 회의명과 비밀번호는 자동으로 입력됩니다.) \n\nstep2 회의 시작하기 또는 회의 참가하기 버튼을 눌러서 회의에 입장합니다. \n\n회의 시작하기는 입력한 회의명으로 새로운 회의방을 개설하는 것을 의미합니다. \n회의 시작하기를 통해 입장한 사용자는 회의방을 처음으로 생성한 사용자이자 마스터권한을 부여 받습니다. 마스터는 일종의 방장 개념이며, 마스터가 회의방에서 퇴장할 시 해당 회의방은 사라집니다. \n\n회의 참가하기는 입력한 회의명에 해당되는 회의방에 참여하는 것을 의미합니다. \n회의 참가하기를 통해 입장한 사용자는 자유롭게 회의방 퇴장 및 재 참여가 가능하며 마스터가 회의방을 퇴장할 시 모든 사용자는 자동으로 퇴장됩니다. \n\nstep3 회의 참가 후 하단의 드로잉 메뉴들과 상단의 이미지 공유 메뉴를 사용하여 그림 및 텍스트, 이미지를 참가자들과 공유합니다."
        let message = NSMutableAttributedString.getAttributedString(fromString: messageString)
        message.boldColor(color: drawingTogetherColor, fontSize: 25, subString: "사용 방법 및 설명")
        message.boldColor(color: drawingTogetherColor, fontSize: 17, subString: "step1")
        message.boldColor(color: drawingTogetherColor, fontSize: 17, subString: "step2")
        message.boldColor(color: drawingTogetherColor, fontSize: 17, subString: "step3")
        message.underLine(subString: "회의 시작하기")
        message.underLine(subString: "회의 참가하기")
        message.underLine(subString: "회의 시작하기")
        message.underLine(subString: "마스터")
        message.underLine(subString: "방장")
        message.underLine(subString: "마스터가 회의방에서 퇴장할 시 해당 회의방은 사라집니다.")
        message.underLine(subString: "회의 참가하기")
        message.underLine(subString: "마스터가 회의방을 퇴장할 시 모든 사용자는 자동으로 퇴장됩니다.")
        
        
        infoLabel.attributedText = message
    }
    
    @IBAction func clickOK(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

extension NSMutableAttributedString {
    class func getAttributedString(fromString string: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: string)
    }
    
    func boldColor(color: UIColor, fontSize: CGFloat, onRange: NSRange) {
        self.addAttributes([NSAttributedString.Key.foregroundColor: color], range: onRange)
        self.addAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: fontSize)], range: onRange)
    }
    
    func boldColor(color: UIColor, fontSize: CGFloat, subString: String) {
        if let range = self.string.range(of: subString) {
            self.boldColor(color: color, fontSize: fontSize, onRange: NSRange(range, in: self.string))
        }
    }

    func underLine(onRange: NSRange) {
        self.addAttributes([NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: onRange)
    }
    
    func underLine(subString: String) {
        if let range = self.string.range(of: subString) {
            self.underLine(onRange: NSRange(range, in: self.string))
        }
    }
}
