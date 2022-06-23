//
//  GroupCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 05.06.22.
//

import UIKit

class GroupCell: UICollectionViewCell {
    
    @IBOutlet var outerView: UIView!
    @IBOutlet var imageOuterView: UIView!
    
    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var groupLabel: UILabel!
    @IBOutlet var groupDescriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(with group: UserGroup){
        groupLabel.text = group.groupTitle
        groupDescriptionLabel.text = group.groupDescription
    }

}
