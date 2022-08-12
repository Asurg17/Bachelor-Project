//
//  GroupInfoPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.07.22.
//

import UIKit
import KeychainSwift
import SDWebImage

class GroupInfoPageVC: UIViewController, GroupInfoActionViewDelegate {
    
    @IBOutlet var groupImageView: UIImageView!
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var groupDescriptionLabel: UILabel!
        
    @IBOutlet var actionStackView: UIStackView!
    @IBOutlet var groupMembersActionView: GroupInfoActionView!
    @IBOutlet var seeMediaActionView: GroupInfoActionView!
    @IBOutlet var leaveGroupActionView: GroupInfoActionView!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    let imagePicker = UIImagePickerController()
    var group: Group?
    
    var groupName: String?
    var groupDescription: String?
    
    var groupHasUpdated = false
    
    var delegate: UpdateGroup?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        
        setupViews()
        checkGroup(group: group)
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
        leaveGroupActionView.delegate = self
    }
    
    func setupImageView() {
        groupImageView.image = group!.groupImage
        
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
        groupNameLabel.text = group!.groupName
        groupDescriptionLabel.text = group!.groupDescription
        
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
    
    func actionDidInitiated(_ sender: GroupInfoActionView) {
        switch sender {
          case groupMembersActionView:
            navigateToGroupMembersPage(group: group!)
          case seeMediaActionView:
            navigateToGroupMediaFilesPage(group: group!)
          default:
            leaveGroup()
        }
    }
    
    func leaveGroup() {
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.leaveGroup(userId: userId, groupId: group!.groupId) { [weak self] result in
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
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
    func uploadGroupImage() {
        if let _ = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.uploadImage(imageKey: Constants.groupImagePrefix + group!.groupId, image: groupImageView.image!) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.groupHasUpdated = true
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
    func updateGroup() {
        if hasLabelsChaned() {
            if let userId = keychain.get(Constants.userIdKey) {
                loader.startAnimating()
                service.saveGroupUpdates(
                    userId: userId,
                    groupId: group!.groupId,
                    groupName: groupName!,
                    groupDescription: groupDescription!
                ) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.loader.stopAnimating()
                        switch result {
                        case .success(_):
                            self.groupHasUpdated = true
                            self.group!.groupName = self.groupName!
                            self.groupNameLabel.text = self.groupName
                            self.group!.groupDescription = self.groupDescription!
                            self.groupDescriptionLabel.text = self.groupDescription
                        case .failure(let error):
                            self.showWarningAlert(warningText: error.localizedDescription.description)
                        }
                    }
                }
            } else {
                showWarningAlert(warningText: Constants.fatalError)
            }
        }
    }
    
    func clearLabels() {
        groupName = ""
        groupDescription = ""
    }
    
    func hasLabelsChaned() -> Bool {
        if groupName == nil || groupName == "" { groupName = groupNameLabel.text }
        if groupDescription == nil || groupDescription == "" { groupDescription = groupDescriptionLabel.text }
        
        if groupName != groupNameLabel.text || groupDescription != groupDescriptionLabel.text {
            return true
        }
        
        return false
    }
    
    
    @IBAction func back() {
        if groupHasUpdated {
            delegate?.update(
                updatedGroup: group!
            )
        }
        navigationController?.popViewController(animated: true)
    }

            
    @objc func showAlert(_ sender:AnyObject){
        let alert = UIAlertController(
            title: "Group Name & Description",
            message: "",
            preferredStyle: .alert
        )
        alert.addTextField(configurationHandler: { [unowned self] textField in
            textField.placeholder = "Group Name"
            textField.text = group!.groupName
            textField.keyboardType = .default
            textField.addTarget(
                self,
                action: #selector(self.groupNameChanged(textField:)),
                for: .editingChanged
            )
        })
        alert.addTextField(configurationHandler: { [unowned self] textField in
            textField.placeholder = "Group Description"
            textField.text = group!.groupDescription
            textField.keyboardType = .default
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
    
    @objc func groupNameChanged(textField: UITextField) {
        groupName = textField.text
    }
    
    @objc func groupDescriptionChanged(textField: UITextField) {
        groupDescription = textField.text
    }
        
    
    @objc func imageViewTapped(_ sender:AnyObject){
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
}

extension GroupInfoPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            groupImageView.image = image
            group!.groupImage = image
            uploadGroupImage()
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}
