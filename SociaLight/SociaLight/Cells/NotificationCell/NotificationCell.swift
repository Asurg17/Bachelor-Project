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
    var userId: String
    var userWholeName: String
    var userImageURL: String
    var isFriendshipRequestNotification: Bool
    
    weak var delegate: NotificationCellDelegate?

    init(requestUniqueKey: String, userId: String, userWholeName: String, userImageURL: String, isFriendshipRequestNotification: Bool, delegate: NotificationCellDelegate?) {
        self.requestUniqueKey = requestUniqueKey
        self.userId = userId
        self.userWholeName = userWholeName
        self.userImageURL = userImageURL
        self.isFriendshipRequestNotification = isFriendshipRequestNotification
        self.delegate = delegate
    }
}

class NotificationCell: UITableViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var userImageView: UIImageView!
    @IBOutlet private var userWholeNameLable: UILabel!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var rejectButton: UIButton!

    var model: NotificationCellModel!
    
    func configure(with model: NotificationCellModel){
        self.model = model
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        userImageView.sd_setImage(
            with: URL(string: model.userImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.userImageView.image = UIImage(named: "user")
                }
            }
        )
        
        userWholeNameLable.text = model.userWholeName
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
    
    @IBAction func acceptFriendship() {
        model.delegate?.friendshipAccepted(self)
    }
    
    @IBAction func rejectFriendship() {
        model.delegate?.friendshipRejected(self)
    }

}
