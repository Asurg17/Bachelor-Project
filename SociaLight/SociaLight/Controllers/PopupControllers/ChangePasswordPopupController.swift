//
//  PopupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import UIKit
import KeychainSwift

class ChangePasswordPopupController: UIViewController {
    
    @IBOutlet var popupView: UIView!
    
    @IBOutlet var oldPasswordOuterView: CustomTextFieldOuterView!
    @IBOutlet var newPasswordOuterView: CustomTextFieldOuterView!
    @IBOutlet var confirmPasswordOuterView: CustomTextFieldOuterView!
    
    @IBOutlet var oldPasswordTextField: DesignableUITextField!
    @IBOutlet var newPasswordTextField: DesignableUITextField!
    @IBOutlet var confirmPasswordTextField: DesignableUITextField!
    
    @IBOutlet var changePasswordButton: UIButton!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        oldPasswordTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        popupView.layer.cornerRadius = popupView.frame.size.width / 10
        
        changePasswordButton.layer.cornerRadius = changePasswordButton.frame.size.height / 3
        changePasswordButton.clipsToBounds = true
    }
    
    func changeUserPassword(){
        if checkIfAllViewsAreFilled() {
            if checkIfPasswordsMatches(pass1: newPasswordTextField.text!,
                                       pass2: confirmPasswordTextField.text!) {
                if newPasswordTextField.text! != oldPasswordTextField.text! {
                    if checkPasswordLength(password: oldPasswordTextField.text!) &&
                       checkPasswordLength(password: newPasswordTextField.text!) {
                        let keychain = KeychainSwift()
                        if let userId = keychain.get("userId") {
                            loader.startAnimating()
                            service.changePassword(
                                userId: userId,
                                oldPassword: oldPasswordTextField.text!,
                                newPassword: newPasswordTextField.text!
                            ) { [weak self] result in
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
                            showWarningAlert(warningText: "Can't change password!")
                        }
                    }
                } else {
                    showWarningAlert(warningText: "Can't use same password!")
                }
            }
        } else {
            showWarningAlert(warningText: "Please fill all the fields!")
        }
    }
    
    func checkIfAllViewsAreFilled() -> Bool {
        if oldPasswordTextField.text     == "" ||
           newPasswordTextField.text     == "" ||
           confirmPasswordTextField.text == "" { return false }
        return true
    }
    
    func handleSuccess(response: String) {
        let alert = UIAlertController(
            title: "Success",
            message: response,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: .default,
                handler: { [unowned self] _ in
                    self.dismissPopup()
                }
            )
        )
        present(alert, animated: true, completion: nil)
    }
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? "Unspecified Error!")
    }
    
    @IBAction func changePassword() {
        changeUserPassword()
    }
    
    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }

}

extension ChangePasswordPopupController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.FlatColor.Blue.Mariner
            field.color = UIColor.FlatColor.Blue.Mariner
        }
        
        switch textField {
        case oldPasswordTextField:
            oldPasswordOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        case newPasswordTextField:
            newPasswordOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        default:
            confirmPasswordOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.lightGray
            field.color = UIColor.lightGray
        }
        
        switch textField {
        case oldPasswordTextField:
            oldPasswordOuterView.borderColor = UIColor.gray.cgColor
        case newPasswordTextField:
            newPasswordOuterView.borderColor = UIColor.gray.cgColor
        default:
            confirmPasswordOuterView.borderColor = UIColor.gray.cgColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case oldPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
        case newPasswordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            changeUserPassword()
        }
        return true
    }
}
