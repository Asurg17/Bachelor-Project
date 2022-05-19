//
//  RoundButton.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.05.22.
//

import UIKit

@IBDesignable
class RoundButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.height / 3
    }
    
}

