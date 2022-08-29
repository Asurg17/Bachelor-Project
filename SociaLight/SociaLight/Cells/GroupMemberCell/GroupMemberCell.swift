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
    var userRole: String
    
    weak var delegate: GroupMemberCellDelegate?

    init(memberId: String, memberFristName: String, memberLastName: String, memberImageURL: String, memberPhone: String, isFriendRequestAlreadySent: String, areAlreadyFriends: String, userRole: String, delegate: GroupMemberCellDelegate?) {
        self.memberId = memberId
        self.memberFristName = memberFristName
        self.memberLastName = memberLastName
        self.memberImageURL = memberImageURL
        self.memberPhone = memberPhone
        self.delegate = delegate
        self.isFriendRequestAlreadySent = isFriendRequestAlreadySent
        self.areAlreadyFriends = areAlreadyFriends
        self.userRole = userRole
    }
}

class GroupMemberCell: UITableViewCell {
    
    @IBOutlet private var memberImageView: UIImageView!
    @IBOutlet private var memberName: UILabel!
    @IBOutlet private var memberPhone: UILabel!
    @IBOutlet private var adminLabel: UILabel!
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
                    self.memberImageView.image = UIImage(named: "empty_avatar_image")
                }
            }
        )
        
        adminLabel.isHidden = !(model.userRole == Constants.admin)
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
    
    @IBAction func handleActionButtonClick() {
        if model.isFriendRequestAlreadySent == "N" {
            model.isFriendRequestAlreadySent = "Y"
            actionButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
            model.delegate?.sendFriendshipRequest(self)
        }
    }
    
    @IBAction func handleUserClick() {
        model.delegate?.userIsClicked(self)
    }
    
}
