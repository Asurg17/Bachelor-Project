//
//  PopupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import UIKit
import KeychainSwift

class ChangePasswordPopupVC: UIViewController {
    
    @IBOutlet var oldPasswordTextField: DesignableUITextField!
    @IBOutlet var newPasswordTextField: DesignableUITextField!
    @IBOutlet var confirmPasswordTextField: DesignableUITextField!
    
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
    }
    
    func changeUserPassword(){
        if checkIfAllViewsAreFilled() {
            if checkIfPasswordsMatches(pass1: newPasswordTextField.text!,
                                       pass2: confirmPasswordTextField.text!) {
                if newPasswordTextField.text! != oldPasswordTextField.text! {
                    if checkPasswordLength(password: oldPasswordTextField.text!) &&
                       checkPasswordLength(password: newPasswordTextField.text!) {
                        let keychain = KeychainSwift()
                        if let userId = keychain.get(Constants.userIdKey) {
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
                            showWarningAlert(warningText: Constants.changePasswordErrorText)
                        }
                    }
                } else {
                    showWarningAlert(warningText: Constants.samePasswordsWarningText)
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fieldsAreNotFilledWarningText)
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
    
    @IBAction func changePassword() {
        changeUserPassword()
    }
    
    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }

}

extension ChangePasswordPopupVC: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.FlatColor.Blue.Mariner
            field.color = UIColor.FlatColor.Blue.Mariner
            field.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.lightGray
            field.color = UIColor.lightGray
            field.borderColor = UIColor.gray.cgColor
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
