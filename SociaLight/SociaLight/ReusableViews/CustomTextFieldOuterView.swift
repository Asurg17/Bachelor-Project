//
//  CustomTextFieldOuterView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 24.04.22.
//

import UIKit

@IBDesignable
class CustomTextFieldOuterView: UIView {
    
    @IBInspectable var borderColor = UIColor.gray.cgColor {
        didSet {
            changeBorderColor()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.layer.borderWidth = 1.2
        self.layer.borderColor = borderColor
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.checkAction))
        self.addGestureRecognizer(gesture)

    }
    
    func changeBorderColor() {
        self.layer.borderColor = borderColor
    }
    
    @objc func checkAction(sender : UITapGestureRecognizer) {
        print("a")
    }
    
}
