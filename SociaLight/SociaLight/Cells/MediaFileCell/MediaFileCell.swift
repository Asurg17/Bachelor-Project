//
//  MediaFileCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 22.08.22.
//

import UIKit

class MediaFileCellModel {
    var imageKey: String
    weak var delegate: MediaFileCellDelegate?
    
    init(imageKey: String, delegate: MediaFileCellDelegate?) {
        self.imageKey = imageKey
        self.delegate = delegate
    }
}


class MediaFileCell: UICollectionViewCell {
    
    @IBOutlet var image: UIImageView!
    
    var model: MediaFileCellModel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with model: MediaFileCellModel) {
        self.model = model
        
        image.sd_setImage(
            with: URL(string: Constants.getImageURLPrefix + model.imageKey),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.image.image = UIImage(named: "empty_image")
                }
            }
        )
    }
    
    @IBAction func handleImageTap() {
        model.delegate?.cellDidClick(self)
    }
    
}
