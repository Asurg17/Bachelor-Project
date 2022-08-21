//
//  ImageOuterView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 22.08.22.
//

import UIKit

@IBDesignable
class ImageOuterView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.borderWidth = 1.25
        self.layer.borderColor = UIColor.random().cgColor
        self.layer.cornerRadius = self.frame.size.width / 2
    }
    
}
