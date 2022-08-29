//
//  NewGroupVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 13.06.22.
//

import UIKit

class NewGroupFirstPageVC: UIViewController {
    
    @IBOutlet var imageOuterView: UIView!
    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var membersCount: UIButton!
    @IBOutlet var groupName: UITextField!
    @IBOutlet var groupDescription: UITextField!

    var isGroupPrivate = false
    
    let imagePicker = UIImagePickerController()
    var pickerView: UIPickerView!
    var pickerValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageOuterView.layer.borderWidth = 2
        imageOuterView.layer.borderColor = UIColor.white.cgColor//UIColor(hexString: "#2a2727").cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        groupName.becomeFirstResponder()
    }
    
    func setupViews() {
        groupName.delegate = self
        groupDescription.delegate = self
        
        groupImage.isUserInteractionEnabled = true
        groupImage.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(imageViewTapped(_:))
            )
        )
    }
    
    func areViewsValid() -> Bool {
        if let name = groupName.text {
            if name.replacingOccurrences(of: " ", with: "").isEmpty {
                showWarningAlert(warningText: Constants.groupNameWarningText)
                return false
            }
        } else {
            showWarningAlert(warningText: Constants.groupNameWarningText)
            return false
        }
        return true
    }

    
    @IBAction func showPicker() {
        pickerView = UIPickerView(frame: CGRect(x: 10, y: 50, width: 250, height: 150))
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let picker = UIAlertController(title: "Members Count", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        picker.view.addSubview(pickerView)
        picker.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                    self.pickerValue = Constants.pickerData[self.pickerView.selectedRow(inComponent: 0)]
                    self.membersCount.setTitle(
                        "Members Count (" + String(self.pickerValue) + ")",
                        for: .normal
                    )
                }
            )
        )
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(picker, animated: true)
    }
    
    @IBAction func changeGroupPrivacy(_ sender: Any) {
        isGroupPrivate.toggle()
    }
    
    @IBAction func navigateToNextVC() {
        if areViewsValid() {
            navigateToNewGroupSecondVC(
                group: Group(
                    groupId: "",
                    groupImage: groupImage.image!,
                    membersCurrentNumber: 1,
                    membersMaxNumber: pickerValue,
                    groupName: groupName.text!,
                    groupDescription: groupDescription.text ?? "",
                    isPrivate: isGroupPrivate,
                    userRole: "A"
                )
            )
        }
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func imageViewTapped(_ sender:AnyObject){
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
}

extension NewGroupFirstPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            groupImage.image = image
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
}


extension NewGroupFirstPageVC: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(Constants.pickerData[row])
    }
    
}

extension NewGroupFirstPageVC: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Constants.pickerData.count
    }
    
}

extension NewGroupFirstPageVC: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == groupName {
            if ((textField.text?.count ?? 0) + string.count) > Constants.groupNameCharactersMaxNum {
                showWarningAlert(warningText: Constants.groupNameCharactersMaxNumWarning)
                return false
            }
        } else if textField == groupDescription {
            if ((textField.text?.count ?? 0) + string.count) > Constants.groupDescriptionCharactersMaxNum {
                showWarningAlert(warningText: Constants.groupDescriptionCharactersMaxNumWarning)
                return false
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case groupName:
            groupDescription.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
