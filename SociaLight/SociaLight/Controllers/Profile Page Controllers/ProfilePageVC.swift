//
//  ProfilePageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.05.22.
//

import UIKit
import KeychainSwift
import SDWebImage
import JGProgressHUD

class ProfilePageVC: UIViewController {
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var birthDateLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var popupButtonsStackView: UIStackView!
    
    private let loader = JGProgressHUD()
    private let imagePicker = UIImagePickerController()
    private let fileService = FileService()
    private let userService = UserService()
    
    var currUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadUserInfo()
    }
   
    func setupViews() {
        let isMyProfile = (currUserId == nil)
        popupButtonsStackView.isHidden = !isMyProfile
        //sendMeetingInvitation.isHidden = isMyProfile
        usernameLabel.isHidden = !isMyProfile
        
        if isMyProfile {
            profileImage.isUserInteractionEnabled = true
            profileImage.addGestureRecognizer(
                UITapGestureRecognizer(
                    target: self,
                    action: #selector(imageViewTapped(_:))
                )
            )
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func loadUserInfo() {
        let userId = currUserId ?? getUserId()
        
        showLoader(text: "Loading...")
        userService.getUserInfo(userId: userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.dismiss(animated: true)
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
        let userId = currUserId ?? getUserId()
        
        showLoader(text: "Uploading...")
        fileService.uploadImage(imageKey: Constants.userImagePrefix + userId, image: userImage) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.dismiss(animated: true)
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
    
    func showLoader(text: String) {
        loader.textLabel.text = text
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    @IBAction func showFriendsPage() {
        navigateToFriendsPage()
    }
    
    @IBAction func showPersonalInfoPopup() {
        navigateToPersonalInfoPopupPage(vc: self)
    }
    
    @IBAction func showChangePasswordPopup() {
        navigateToChangePasswordPopupPage()
    }
    
    @IBAction func signOut() {
        if let tc = self.tabBarController,
           let vcs = tc.viewControllers,
           let nc = vcs[0] as? UINavigationController,
           let vc = nc.viewControllers[0] as? MainPageVC {
            vc.close()
        } else {
            fatalError(Constants.fatalError)
        }
            
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

extension ProfilePageVC: DismissProtocol {
    func refresh() {
        loadUserInfo()
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
