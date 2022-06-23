//
//  SelectedFriendCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 23.06.22.
//

import UIKit

class SelectedFriendCell: UICollectionViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var selectedFriendImage: UIImageView!
    @IBOutlet private var selectedFriendFirstName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageOuterView.layer.borderWidth = 1
        imageOuterView.layer.borderColor = UIColor.white.cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    func configure(with selectedFriend: UserFriend){
        selectedFriendFirstName.text = selectedFriend.friendFirstName
    }

}
