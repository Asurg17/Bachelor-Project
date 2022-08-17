//
//  NotificationCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 07.08.22.
//

import UIKit
import SDWebImage

class NotificationCellModel {
    var requestUniqueKey: String
    var fromUserId: String
    var fromUserWholeName: String
    var fromUserImageURL: String
    var isFriendshipRequest: Bool
    var groupId: String
    var groupImageURL: String
    var groupTitle: String
    var groupDescription: String
    var groupCapacity: String
    var membersCount: String
    var image: UIImage
    
    weak var delegate: NotificationCellDelegate?

    init(requestUniqueKey: String, fromUserId: String, fromUserWholeName: String, fromUserImageURL: String, isFriendshipRequest: Bool, groupId: String, groupImageURL: String, groupTitle: String, groupDescription: String, groupCapacity: String, membersCount: String, delegate: NotificationCellDelegate?) {
        self.requestUniqueKey = requestUniqueKey
        self.fromUserId = fromUserId
        self.fromUserWholeName = fromUserWholeName
        self.fromUserImageURL = fromUserImageURL
        self.isFriendshipRequest = isFriendshipRequest
        self.groupId = groupId
        self.groupImageURL = groupImageURL
        self.groupTitle = groupTitle
        self.groupDescription = groupDescription
        self.groupCapacity = groupCapacity
        self.membersCount = membersCount
        self.image = UIImage()
        self.delegate = delegate
    }
}

class NotificationCell: UITableViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var notificationImageView: UIImageView!
    @IBOutlet private var notificationHeaderLabel: UILabel!
    @IBOutlet private var notificationDescriptionLabel: UILabel!
    @IBOutlet private var friendshipButtonsStackView: UIStackView!
    @IBOutlet private var navigationButton: UIButton!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var rejectButton: UIButton!

    var model: NotificationCellModel!
    
    func configure(with model: NotificationCellModel){
        self.model = model
    
        var imageURL = ""
        if model.isFriendshipRequest {
            navigationButton.isHidden = true
            imageURL = model.fromUserImageURL
            notificationHeaderLabel.text = model.fromUserWholeName
            notificationDescriptionLabel.text = "Wants to be your friend"
            acceptButton.setTitle("Accept", for: .normal)
        } else {
            navigationButton.isHidden = false
            imageURL = model.groupImageURL
            notificationHeaderLabel.text = model.fromUserWholeName
            notificationDescriptionLabel.text = "Invited you to join: " + model.groupTitle
            acceptButton.setTitle("Join", for: .normal)
        }
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        notificationImageView.sd_setImage(
            with: URL(string: imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    if model.isFriendshipRequest {
                        self.notificationImageView.image = UIImage(named: "user")
                    } else {
                        self.notificationImageView.image = UIImage(named: "GroupIcon")
                    }
                }
                self.model.image = self.notificationImageView.image!
            }
        )
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
    
    @IBAction func navigateToGroupPage() {
        model.delegate?.navigateToGroupPage(self)
    }
    
    @IBAction func acceptFriendship() {
        if model.isFriendshipRequest {
            model.delegate?.friendshipAccepted(self)
        } else {
            model.delegate?.acceptInvitation(self)
        }
    }
    
    @IBAction func rejectFriendship() {
        if model.isFriendshipRequest {
            model.delegate?.friendshipRejected(self)
        } else {
            model.delegate?.rejectInvitation(self)
        }
    }

}
