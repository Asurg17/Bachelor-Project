//
//  SelectedFriendCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 23.06.22.
//

import UIKit

class SelectedFriendCellModel {
    var friendId: String
    var friendFristName: String
    var friendImage: UIImage
    
    init(friendId: String, friendFristName: String, friendImage: UIImage) {
        self.friendId = friendId
        self.friendFristName = friendFristName
        self.friendImage = friendImage
    }
}


class SelectedFriendCell: UICollectionViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var selectedFriendImage: UIImageView!
    @IBOutlet private var selectedFriendFirstName: UILabel!
    
    var model: SelectedFriendCellModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageOuterView.layer.borderWidth = 1
        imageOuterView.layer.borderColor = UIColor.white.cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    func configure(with model: SelectedFriendCellModel){
        self.model = model
        
        selectedFriendImage.image = model.friendImage
        selectedFriendFirstName.text = model.friendFristName
    }

}
