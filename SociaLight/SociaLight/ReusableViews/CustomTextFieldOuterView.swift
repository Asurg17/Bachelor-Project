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
        self.layer.cornerRadius = self.frame.size.height / 1.90
        self.layer.borderWidth = 1.2
        self.layer.borderColor = borderColor
    }
    
    func changeBorderColor() {
        self.layer.borderColor = borderColor
    }
    
}
