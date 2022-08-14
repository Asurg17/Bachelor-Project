//
//  RoundCornerTextField.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 04.06.22.
//

import UIKit

@IBDesignable
class RoundCornerTextField: UITextField {
    
    @IBInspectable var paddingLeft: CGFloat = 0
    @IBInspectable var paddingRight: CGFloat = 0
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        let insets = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingRight)
        return rect.inset(by: insets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        let insets = UIEdgeInsets(top: 0, left: paddingLeft, bottom: 0, right: paddingRight)
        return rect.inset(by: insets)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.darkGray.cgColor
        
        self.clearButtonMode = .whileEditing
        
        if let button = self.value(forKey: "clearButton") as? UIButton {
            button.tintColor = .black
            button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        }
    }
    
     override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let originalRect = super.clearButtonRect(forBounds: bounds)
        return originalRect.offsetBy(dx: -10, dy: 0)
    }
}

