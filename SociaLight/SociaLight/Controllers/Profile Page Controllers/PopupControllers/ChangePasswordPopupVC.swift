//
//  PopupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import UIKit

class ChangePasswordPopupVC: UIViewController {
    
    @IBOutlet var oldPasswordTextField: DesignableUITextField!
    @IBOutlet var newPasswordTextField: DesignableUITextField!
    @IBOutlet var confirmPasswordTextField: DesignableUITextField!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var button: UIButton!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        hideKeyboardWhenTappedAround()
        registerForKeyboardNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
                        let userId = getUserId()
                        
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
                                case .success(_):
                                    self.dismissPopup()
                                case .failure(let error):
                                    self.showWarningAlert(warningText: error.localizedDescription.description)
                                }
                            }
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
    
    @IBAction func changePassword() {
        changeUserPassword()
    }
    
    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func keyboardWillChange(notification: NSNotification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else  {
            return
        }
    
        if notification.name == UIResponder.keyboardWillShowNotification
            || notification.name == UIResponder.keyboardWillChangeFrameNotification {

            let lastViewYCoordinate = contentView.frame.origin.y + button.frame.origin.y + button.frame.height
            
            if keyboardRect.origin.y < lastViewYCoordinate {
                view.frame.origin.y = keyboardRect.origin.y - lastViewYCoordinate - Constants.bottomOffset
            }
        } else {
            view.frame.origin.y = 0
        }
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
