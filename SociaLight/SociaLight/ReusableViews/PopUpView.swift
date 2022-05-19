//
//  PopUpView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.05.22.
//

import UIKit

@IBDesignable
class PopUpView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.width / 10
    }
    
}
