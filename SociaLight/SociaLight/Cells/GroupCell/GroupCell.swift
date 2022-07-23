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
    
    weak var delegate: GroupCellDelegate?
    
    init(groupId: String, groupTitle: String, groupDescription: String, groupImageURL: String, delegate: GroupCellDelegate?) {
        self.groupId = groupId
        self.groupTitle = groupTitle
        self.groupDescription = groupDescription
        self.groupImageURL = groupImageURL
        self.delegate = delegate
    }
}

protocol GroupCellDelegate: AnyObject {
    func cellDidClick(_ friend: GroupCell)
}

class GroupCell: UICollectionViewCell {
    
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
            with: URL(string: model.groupImageURL),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.groupImage.image = UIImage(named: "GroupIcon")
                }
            }
        )
        
        groupLabel.text = model.groupTitle
        groupDescriptionLabel.text = model.groupDescription
    }
    
    @IBAction func navigateToMainPage() {
        model.delegate?.cellDidClick(self)
    }

}
