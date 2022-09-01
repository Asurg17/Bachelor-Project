//
//  CustomDropDownCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import DropDown
import SDWebImage

class CustomDropDownCell: DropDownCell {
    
    @IBOutlet var userImage: UIImageView!

    func configure(with userId: String) {
        userImage.sd_setImage(
            with: URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.userImage.image = UIImage(named: "empty_avatar_image")
                }
          })
    }
}
