//
//  RoundCornerView.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.09.22.
//

import UIKit

@IBDesignable
class RoundCornerView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
    }
}
