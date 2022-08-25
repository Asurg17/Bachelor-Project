//
//  GroupMemberProfilePageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 21.08.22.
//

import UIKit
import SDWebImage

class GroupMemberProfilePageVC: UIViewController {
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var birthDateLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    
    var currUserId: String?
 
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadUserInfo()
    }
    
    func loadUserInfo() {
        if let userId = currUserId {
            loader.startAnimating()
            service.getUserInfo(userId: userId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(let response):
                        self.reloadView(userInfo: response, userId: userId)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: "Can't load user info")
        }
    }
    
    func reloadView(userInfo: UserInfoResponse, userId: String){
        
        if self.profileImage.image == nil {
            SDImageCache.shared.clearMemory()
            SDImageCache.shared.clearDisk()
            
            profileImage.sd_setImage(
                with: URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
                completed: { (image, error, cacheType, imageURL) in
                    if image == nil {
                        self.profileImage.image = UIImage(named: "empty_avatar_image")
                    }
                }
            )
        }
        
        usernameLabel.text = userInfo.username
        firstNameLabel.text = userInfo.firstName
        lastNameLabel.text = userInfo.lastName
        ageLabel.text = userInfo.age
        birthDateLabel.text = userInfo.birthDate
        phoneLabel.text = userInfo.phone
    }

    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
}
