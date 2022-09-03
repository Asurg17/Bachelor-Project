//
//  FriendCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 23.06.22.
//

import UIKit
import SDWebImage

class FriendCellModel {
    var friendId: String
    var friendFristName: String
    var friendLastName: String
    var friendImageURL: String
    var friendImage: UIImage
    var friendPhone: String
    var isSelected: Bool
    var isFriendsPage: Bool
    
    weak var delegate: FriendCellDelegate?

    init(friendId: String, friendFristName: String, friendLastName: String, friendImageURL: String, friendPhone: String, isSelected: Bool, isFriendsPage: Bool, delegate: FriendCellDelegate?) {
        self.friendId = friendId
        self.friendFristName = friendFristName
        self.friendLastName = friendLastName
        self.friendImageURL = friendImageURL
        self.friendPhone = friendPhone
        self.friendImage = UIImage()
        self.isSelected = isSelected
        self.isFriendsPage = isFriendsPage
        self.delegate = delegate
    }
}

class FriendCell: UITableViewCell {
    
    @IBOutlet private var friendImageView: UIImageView!
    @IBOutlet private var friendName: UILabel!
    @IBOutlet private var friendPhone: UILabel!
    @IBOutlet private var checkboxOuterView: UIView!
    @IBOutlet private var checkboxInnerView: UIView!
    @IBOutlet private var button: UIButton!

    var model: FriendCellModel!
    
    func configure(with model: FriendCellModel){
        self.model = model
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        friendImageView.sd_setImage(
            with: URL(string: model.friendImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.friendImageView.image = UIImage(named: "empty_avatar_image")
                }
                self.model.friendImage = self.friendImageView.image!
            }
        )
        
        friendName.text = model.friendFristName + " " + model.friendLastName
        friendPhone.text = model.friendPhone
        
        checkIfCellIsSelected()
        checkboxOuterView.isHidden = model.isFriendsPage
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = subviews[0].frame.width
        for view in subviews where view != contentView {
            if view.frame.width == width {
                view.removeFromSuperview()
            }
        }
        
        checkboxInnerView.layer.cornerRadius = checkboxInnerView.frame.size.width / 2
        
        checkboxOuterView.layer.borderWidth = 1
        checkboxOuterView.layer.borderColor = UIColor.gray.cgColor
        checkboxOuterView.layer.cornerRadius = checkboxOuterView.frame.size.width / 2
    }
    
    func checkIfCellIsSelected() {
        if model.isSelected {
            checkboxInnerView.isHidden = false
        } else {
            checkboxInnerView.isHidden = true
        }
    }
    
    func toggleSelection() {
        model.isSelected.toggle()
        checkIfCellIsSelected()
    }
    
    @IBAction func handleCellClick() {
        toggleSelection()
        model.delegate?.cellDidClick(self)
    }
    
}
