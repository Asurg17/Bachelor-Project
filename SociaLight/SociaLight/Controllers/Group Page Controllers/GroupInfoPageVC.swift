//
//  GroupInfoPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.07.22.
//

import UIKit
import SDWebImage

class GroupInfoPageVC: UIViewController, GroupInfoActionViewDelegate {
    
    @IBOutlet var groupImageView: UIImageView!
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var groupDescriptionLabel: UILabel!
        
    @IBOutlet var actionStackView: UIStackView!
    @IBOutlet var groupMembersActionView: GroupInfoActionView!
    @IBOutlet var seeMediaActionView: GroupInfoActionView!
    @IBOutlet var createNewEventActionView: GroupInfoActionView!
    @IBOutlet var leaveGroupActionView: GroupInfoActionView!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    
    let imagePicker = UIImagePickerController()
    
    var groupName: String?
    var groupDescription: String?
    
    var groupHasUpdated = false
    
    var delegate: UpdateGroup?
    
    var response: GetGroupTitleAndDescriptionResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getGroupTitleAndDescription()
    }
    
    func setupViews() {
        setupActionViews()
        setupImageView()
        setupStackView()
        setupLabels()
    }
    
    func setupActionViews() {
        groupMembersActionView.delegate = self
        seeMediaActionView.delegate = self
        createNewEventActionView.delegate = self
        leaveGroupActionView.delegate = self
        
        let isUserGroupMember = UserDefaults.standard.bool(forKey: "isUserGroupMember")
        groupMembersActionView.isHidden = !isUserGroupMember
        leaveGroupActionView.isHidden = !isUserGroupMember
    }
    
    func setupImageView() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()

        groupImageView.sd_setImage(
            with: URL(string: (Constants.getImageURLPrefix + Constants.groupImagePrefix + getGroupId()).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.groupImageView.image = UIImage(named: "GroupIcon")
                }
            }
        )
        
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(imageViewTapped(_:))
            )
        )
    }
    
    func setupStackView() {
        actionStackView.clipsToBounds = true
        actionStackView.layer.cornerRadius = actionStackView.frame.size.width / 20
    }
    
    func setupLabels() {
    
        groupNameLabel.isUserInteractionEnabled = true
        groupNameLabel.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(showAlert(_:))
            )
        )
        groupDescriptionLabel.isUserInteractionEnabled = true
        groupDescriptionLabel.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(showAlert(_:))
            )
        )
    }
    
    func getGroupTitleAndDescription() {
        let userId = getUserId()
        let groupId = getGroupId()
        
        let parameters = [
            "userId": userId,
            "groupId": groupId
        ]
        
        loader.startAnimating()
        service.getGroupTitleAndDescription(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                switch result {
                case .success(let response):
                    self.response = response
                    self.groupNameLabel.text = response.groupTitle
                    self.groupDescriptionLabel.text = response.groupDescription
                    self.createNewEventActionView.isHidden = (response.userRole != Constants.admin)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func actionDidInitiated(_ sender: GroupInfoActionView) {
        switch sender {
          case groupMembersActionView:
            navigateToGroupMembersPage()
          case seeMediaActionView:
            navigateToGroupMediaFilesPage()
        case createNewEventActionView:
            navigateNewEventPagePage()
          case leaveGroupActionView:
            leaveGroup()
          default:
            ()
        }
    }
    
    func leaveGroup() {
        let userId = getUserId()
        let groupId = getGroupId()
        
        loader.startAnimating()
        service.leaveGroup(userId: userId, groupId: groupId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                switch result {
                case .success(_):
                    self.navigationController?.popToRootViewController(animated: true)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func uploadGroupImage(image: UIImage) {
        let _ = getUserId()
            
        loader.startAnimating()
        service.uploadImage(imageKey: Constants.groupImagePrefix + getGroupId(), image: image) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                switch result {
                case .success(_):
                    self.groupImageView.image = image
                    self.groupHasUpdated = true
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func updateGroup() {
        if hasLabelsChaned() {
            let userId = getUserId()
            let groupId = getGroupId()
                
            loader.startAnimating()
            service.saveGroupUpdates(
                userId: userId,
                groupId: groupId,
                groupName: (groupName ?? groupNameLabel.text)!,
                groupDescription: (groupDescription ?? groupDescriptionLabel.text) ?? ""
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.groupHasUpdated = true
                        self.groupNameLabel.text = self.groupName
                        self.groupDescriptionLabel.text = self.groupDescription
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        }
    }
    
    func clearLabels() {
        groupName = ""
        groupDescription = ""
    }
    
    func hasLabelsChaned() -> Bool {
        if groupName == nil || groupName == "" { groupName = groupNameLabel.text }
        if groupDescription == nil { groupDescription = groupDescriptionLabel.text }
        
        if groupName != groupNameLabel.text || groupDescription != groupDescriptionLabel.text {
            return true
        }
        
        return false
    }
    
    
    @IBAction func back() {
        if groupHasUpdated {
            if let groupTitle = groupNameLabel.text {
                delegate?.update(
                    groupTitle: groupTitle
                )
            }
        }
        navigationController?.popViewController(animated: true)
    }

            
    @objc func showAlert(_ sender:AnyObject){
        guard let userRole = response?.userRole else { return }
        if UserDefaults.standard.bool(forKey: "isUserGroupMember") && userRole == Constants.admin {
            let alert = UIAlertController(
                title: "Group Name & Description",
                message: "",
                preferredStyle: .alert
            )
            alert.addTextField(configurationHandler: { [unowned self] textField in
                textField.placeholder = "Group Name"
                textField.text = groupNameLabel.text
                textField.keyboardType = .default
                textField.delegate = self
                textField.addTarget(
                    self,
                    action: #selector(self.groupNameChanged(textField:)),
                    for: .editingChanged
                )
            })
            alert.addTextField(configurationHandler: { [unowned self] textField in
                textField.placeholder = "Group Description"
                textField.text = groupDescriptionLabel.text
                textField.keyboardType = .default
                textField.delegate = self
                textField.addTarget(
                    self,
                    action: #selector(self.groupDescriptionChanged(textField:)),
                    for: .editingChanged
                )
            })
            alert.addAction(
                UIAlertAction(
                    title: "Save",
                    style: .default,
                    handler: { [unowned self] _ in
                        self.updateGroup()
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: { [unowned self] _ in
                        self.clearLabels()
                    }
                )
            )
            present(alert, animated: true)
        }
    }
    
    
    @objc func groupNameChanged(textField: UITextField) {
        if let text = textField.text {
            groupHasUpdated = true
            groupName = text
        }
    }
    
    @objc func groupDescriptionChanged(textField: UITextField) {
        if let text = textField.text {
            groupHasUpdated = true
            groupDescription = text
        }
    }
    
    @objc func imageViewTapped(_ sender:AnyObject){
        guard let userRole = response?.userRole else { return }
        if UserDefaults.standard.bool(forKey: "isUserGroupMember") && userRole == Constants.admin {
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true)
        }
    }
    
}

extension GroupInfoPageVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.placeholder == "Group Name" {
            if ((textField.text?.count ?? 0) + string.count) > Constants.groupNameCharactersMaxNum {
                return false
            }
        } else if textField.placeholder == "Group Description" {
            if ((textField.text?.count ?? 0) + string.count) > Constants.groupDescriptionCharactersMaxNum {
                return false
            }
        }
        return true
    }
}


extension GroupInfoPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            uploadGroupImage(image: image)
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
