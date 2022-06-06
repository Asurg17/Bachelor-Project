//
//  GroupCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 05.06.22.
//

import UIKit

class GroupCell: UICollectionViewCell {
    
    @IBOutlet var outerView: UIView!
    
    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var groupLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
//        outerView.layer.cornerRadius = 10
//        outerView.layer.borderWidth = 1
//        outerView.layer.borderColor = UIColor.gray.cgColor
    }
    
    func configure(with group: UserGroup){
        //groupImage.image = "image"
        groupLabel.text = group.groupTitle
    }

}
