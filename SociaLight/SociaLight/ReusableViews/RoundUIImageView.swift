//
//  RoundUIImageView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 12.05.22.
//

import UIKit

@IBDesignable
class RoundUIImageView: UIImageView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = true
        self.layer.borderWidth = 1.5
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.size.width / 2
    }
    
}
