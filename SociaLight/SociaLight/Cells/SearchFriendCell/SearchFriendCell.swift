//
//  SearchFriendCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 03.09.22.
//

import UIKit
import SDWebImage

class SearchFriendCellModel {
    var userId: String
    var userFristName: String
    var userLastName: String
    
    weak var delegate: SearchFriendCellDelegate?

    init(userId: String, userFristName: String, userLastName: String, delegate: SearchFriendCellDelegate?) {
        self.userId = userId
        self.userFristName = userFristName
        self.userLastName = userLastName
        self.delegate = delegate
    }
}

class SearchFriendCell: UITableViewCell {
    
    @IBOutlet private var userImageView: UIImageView!
    @IBOutlet private var userName: UILabel!
    @IBOutlet private var actionButton: UIButton!
    
    private var isFrienshipRequestAlreadySent = false

    var model: SearchFriendCellModel!
    
    func configure(with model: SearchFriendCellModel){
        self.model = model
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
        
        userImageView.sd_setImage(
            with: URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + model.userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.userImageView.image = UIImage(named: "empty_avatar_image")
                }
            }
        )
        
        userName.text = model.userFristName + " " + model.userLastName
        actionButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        isFrienshipRequestAlreadySent = false
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
        actionButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    }
    
    @IBAction func handleActionButtonClick() {
        if !isFrienshipRequestAlreadySent {
            isFrienshipRequestAlreadySent = true
            model.delegate?.sendFriendshipRequest(self)
        }
    }
    
    @IBAction func handleUserClick() {
        model.delegate?.userIsClicked(self)
    }

}
