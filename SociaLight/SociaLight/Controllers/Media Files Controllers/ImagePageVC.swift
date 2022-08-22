//
//  ImagePageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 20.08.22.
//

import UIKit
import SDWebImage

class ImagePageVC: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photo"
        
        setupScrollView()
        downloadImage()
    }
    
    func setupScrollView() {
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
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

extension ImagePageVC: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
