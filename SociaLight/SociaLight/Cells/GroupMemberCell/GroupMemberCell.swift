//
//  GroupMemberCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.08.22.
//

import UIKit
import SDWebImage

class GroupMemberCellModel {
    var memberId: String
    var memberFristName: String
    var memberLastName: String
    var memberImageURL: String
    var memberPhone: String
    var isFriendRequestAlreadySent: String
    var areAlreadyFriends: String
    
    weak var delegate: GroupMemberCellDelegate?

    init(memberId: String, memberFristName: String, memberLastName: String, memberImageURL: String, memberPhone: String, isFriendRequestAlreadySent: String, areAlreadyFriends: String, delegate: GroupMemberCellDelegate?) {
        self.memberId = memberId
        self.memberFristName = memberFristName
        self.memberLastName = memberLastName
        self.memberImageURL = memberImageURL
        self.memberPhone = memberPhone
        self.delegate = delegate
        self.isFriendRequestAlreadySent = isFriendRequestAlreadySent
        self.areAlreadyFriends = areAlreadyFriends
    }
}

class GroupMemberCell: UITableViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var memberImageView: UIImageView!
    @IBOutlet private var memberName: UILabel!
    @IBOutlet private var memberPhone: UILabel!
    @IBOutlet private var actionButton: UIButton!

    var model: GroupMemberCellModel!
    
    func configure(with model: GroupMemberCellModel){
        self.model = model
        
        setIcon()
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        memberImageView.sd_setImage(
            with: URL(string: model.memberImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.memberImageView.image = UIImage(named: "user")
                }
            }
        )
        
        memberName.text = model.memberFristName + " " + model.memberLastName
        memberPhone.text = model.memberPhone
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = subviews[0].frame.width
        for view in subviews where view != contentView {
            if view.frame.width == width {
                view.removeFromSuperview()
            }
        }
        
        imageOuterView.layer.borderWidth = 1.25
        imageOuterView.layer.borderColor = UIColor.random().cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    func setIcon() {
        if model.areAlreadyFriends == "Y" {
            actionButton.isHidden = true
        } else if model.isFriendRequestAlreadySent == "Y" {
            actionButton.isHidden = false
            actionButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        } else {
            actionButton.isHidden = false
            actionButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        }
    }
    
    @IBAction func handleCellClick() {
        if model.isFriendRequestAlreadySent == "N" {
            model.isFriendRequestAlreadySent = "Y"
            actionButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
            model.delegate?.cellDidClick(self)
        }
    }
    
}
