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
    var notificationTitle: String
    var notificationText: String
    var notificationType: String
    var groupId: String
    var groupTitle: String
    var groupDescription: String
    var groupCapacity: String
    var membersCount: String
    var sendDate: String
    var sendTime: String
    var image: UIImage
    
    weak var delegate: NotificationCellDelegate?

    init(requestUniqueKey: String, fromUserId: String, notificationTitle: String, notificationText: String, notificationType: String, groupId: String, groupTitle: String, groupDescription: String, groupCapacity: String, membersCount: String, sendDate: String, sendTime: String, delegate: NotificationCellDelegate?) {
        self.requestUniqueKey = requestUniqueKey
        self.fromUserId = fromUserId
        self.notificationTitle = notificationTitle
        self.notificationText = notificationText
        self.notificationType = notificationType
        self.groupId = groupId
        self.groupTitle = groupTitle
        self.groupDescription = groupDescription
        self.groupCapacity = groupCapacity
        self.membersCount = membersCount
        self.sendDate = sendDate
        self.sendTime = sendTime
        self.image = UIImage()
        self.delegate = delegate
    }
}

class NotificationCell: UITableViewCell {
    
    @IBOutlet private var notificationImageView: UIImageView!
    @IBOutlet private var notificationTitleLabel: UILabel!
    @IBOutlet private var notificationTextLabel: UILabel!
    @IBOutlet private var notificationTimeLabel: UILabel!
    @IBOutlet private var friendshipButtonsStackView: UIStackView!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var rejectButton: UIButton!

    var model: NotificationCellModel!
    
    func configure(with model: NotificationCellModel) {
        self.model = model
    
        notificationTitleLabel.text = model.notificationTitle
        notificationTextLabel.text = model.notificationText
        notificationTimeLabel.text = model.sendTime
        
        acceptButton.isHidden = (model.notificationType == Constants.defaultNotificationKey)
        rejectButton.isHidden = (model.notificationType == Constants.defaultNotificationKey)
        
        if model.notificationType == Constants.friendshipRequestNotificationKey {
            acceptButton.setTitle("Accept", for: .normal)
        } else if model.notificationType == Constants.groupInvitationNotificationKey {
            acceptButton.setTitle("Join", for: .normal)
        }
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        notificationImageView.sd_setImage(
            with: URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + model.fromUserId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.notificationImageView.image = UIImage(named: "empty_avatar_image")
                }
                self.model.image = self.notificationImageView.image!
            }
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        let width = subviews[0].frame.width
//        for view in subviews where view != contentView {
//            if view.frame.width == width {
//                view.removeFromSuperview()
//            }
//        }
    }
    
    @IBAction func navigate() {
        if model.notificationType == Constants.friendshipRequestNotificationKey {
            model.delegate?.navigateToUserPage(self)
        } else if model.notificationType == Constants.groupInvitationNotificationKey {
            model.delegate?.navigateToGroupPage(self)
        }
    }
    
    @IBAction func accept() {
        if model.notificationType == Constants.friendshipRequestNotificationKey {
            model.delegate?.friendshipAccepted(self)
        } else if model.notificationType == Constants.groupInvitationNotificationKey {
            model.delegate?.acceptInvitation(self)
        }
    }
    
    @IBAction func reject() {
        if model.notificationType == Constants.friendshipRequestNotificationKey {
            model.delegate?.friendshipRejected(self)
        } else if model.notificationType == Constants.groupInvitationNotificationKey {
            model.delegate?.rejectInvitation(self)
        }
    }

}
