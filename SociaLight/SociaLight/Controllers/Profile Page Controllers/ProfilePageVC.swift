//
//  ProfilePageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.05.22.
//

import UIKit
import KeychainSwift
import SDWebImage

class ProfilePageVC: UIViewController, DismissProtocol {
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var birthDateLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadUserInfo()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PersonalInfoPopupVC {
            destination.delegate = self
        }
    }
   
    func setupViews() {
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(imageViewTapped(_:))
            )
        )
    }
    
    func refresh() {
        loadUserInfo()
    }
    
    func loadUserInfo() {
        let userId = getUserId()
        
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
    }

    func uploadUserImage(userImage: UIImage) {
        let userId = getUserId()
        
        loader.startAnimating()
        service.uploadImage(imageKey: Constants.userImagePrefix + userId, image: userImage) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                switch result {
                case .success(_):
                    ()
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
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
        saveInfo(userInfo: userInfo)
    }
    
    func saveInfo(userInfo: UserInfoResponse) {
        UserDefaults.standard.set(userInfo.age, forKey: "user.age")
        UserDefaults.standard.set(userInfo.phone, forKey: "user.phone")
        UserDefaults.standard.set(userInfo.birthDate, forKey: "user.birthDate")
    }
    
    
    @IBAction func signOut() {
        let keychain = KeychainSwift()
        keychain.delete(Constants.userIdKey)
        self.parent?.navigationController?.popToRootViewController(animated: true)
    }

    
    @objc func imageViewTapped(_ sender:AnyObject){
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
}

extension ProfilePageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            uploadUserImage(userImage: image)
            profileImage.image = image
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
