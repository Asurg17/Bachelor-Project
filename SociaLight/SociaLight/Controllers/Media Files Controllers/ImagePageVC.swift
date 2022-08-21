//
//  ImagePageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 20.08.22.
//

import UIKit
import SDWebImage

class ImagePageVC: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photo"
        
        downloadImage()
    }
    
    func downloadImage() {
        imageView.sd_setImage(
            with: url,
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.imageView.image = UIImage(named: "royal")
                }
            }
        )
    }
    
}
