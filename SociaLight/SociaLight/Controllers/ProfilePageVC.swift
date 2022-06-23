//
//  ProfilePageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.05.22.
//

import UIKit
import KeychainSwift

class ProfilePageVC: UIViewController, DismissProtocol {
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var firstNameLabel: UILabel!
    @IBOutlet var lastNameLabel: UILabel!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var birthDateLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
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
        let keychain = KeychainSwift()
        if let userId = keychain.get("userId") {
            loader.startAnimating()
            service.getUserInfo(userId: userId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(let response):
                        self.handleSuccess(response: response)
                    case .failure(let error):
                        self.handleError(error: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: "Could not get user Info!")
        }
    }
    
    func handleSuccess(response: UserInfoResponse) {
        reloadView(userInfo: response)
    }
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? "Unspecified Error!")
    }
    
    func reloadView(userInfo: UserInfoResponse){
        usernameLabel.text = userInfo.username
        firstNameLabel.text = userInfo.firstName
        lastNameLabel.text = userInfo.lastName
        ageLabel.text = userInfo.age
        locationLabel.text = userInfo.location
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
        keychain.delete("userId")
        self.parent?.navigationController?.popToRootViewController(animated: true)
    }

    
    @objc func imageViewTapped(_ sender:AnyObject){
        print("wefwefew")
    }
    
}
