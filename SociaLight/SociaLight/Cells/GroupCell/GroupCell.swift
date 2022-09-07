//
//  GroupCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 05.06.22.
//

import UIKit
import SDWebImage

class GroupCellModel {
    var groupId: String
    var groupTitle: String
    var groupDescription: String
    var groupImageURL: String
    var groupCapacity: String
    var groupMembersNum: String
    var userRole: String
    var newMessagesCount: String
    
    weak var delegate: GroupCellDelegate?
    
    init(groupId: String, groupTitle: String, groupDescription: String, groupImageURL: String, groupCapacity: String, groupMembersNum: String, userRole: String, newMessagesCount: String, delegate: GroupCellDelegate?) {
        self.groupId = groupId
        self.groupTitle = groupTitle
        self.groupDescription = groupDescription
        self.groupImageURL = groupImageURL
        self.groupCapacity = groupCapacity
        self.groupMembersNum = groupMembersNum
        self.userRole = userRole
        self.newMessagesCount = newMessagesCount
        self.delegate = delegate
    }
}

class GroupCell: UICollectionViewCell {
    
    @IBOutlet var bagdeView: UIView!
    @IBOutlet var outerView: UIView!
    @IBOutlet var imageOuterView: UIView!
    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var groupLabel: UILabel!
    @IBOutlet var groupDescriptionLabel: UILabel!
    
    var model: GroupCellModel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configure(with model: GroupCellModel){
        self.model = model
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()

        groupImage.sd_setImage(
            with: URL(string: model.groupImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.groupImage.image = UIImage(named: "GroupIcon")
                }
            }
        )
        
        groupLabel.text = model.groupTitle
        groupDescriptionLabel.text = model.groupDescription
        bagdeView.isHidden = model.newMessagesCount == "0"
    }
    
    @IBAction func navigateToMainPage() {
        model.delegate?.cellDidClick(self)
    }

}
