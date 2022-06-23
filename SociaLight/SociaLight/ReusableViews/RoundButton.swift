//
//  RoundButton.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.06.22.
//

import UIKit

@IBDesignable
class RoundButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.8
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.cornerRadius = self.frame.size.width / 2
    }
    
}
