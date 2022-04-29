//
//  SignUpPageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 24.04.22.
//

import UIKit

class SignUpPageController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var fullNameOuterView:        CustomTextFieldOuterView!
    @IBOutlet var usernameOuterView:        CustomTextFieldOuterView!
    @IBOutlet var phoneNumberOuterView:     CustomTextFieldOuterView!
    @IBOutlet var passwordOuterView:        CustomTextFieldOuterView!
    @IBOutlet var confirmPasswordOuterView: CustomTextFieldOuterView!
    
    @IBOutlet var fullNameTextField:        DesignableUITextField!
    @IBOutlet var usernameTextField:        DesignableUITextField!
    @IBOutlet var phoneNumberTextField:     DesignableUITextField!
    @IBOutlet var passwordTextField:        DesignableUITextField!
    @IBOutlet var confirmPasswordTextField: DesignableUITextField!
    
    @IBOutlet var signInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
        setupViews()
    }
    
    func registerForKeyboardNotifications() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func setupViews() {
        fullNameTextField.delegate = self
        usernameTextField.delegate = self
        phoneNumberTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        signInButton.layer.cornerRadius = signInButton.frame.size.height / 3
        signInButton.clipsToBounds = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.FlatColor.Blue.Mariner
            field.color = UIColor.FlatColor.Blue.Mariner
        }
        
        switch textField {
        case fullNameTextField:
            fullNameOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        case usernameTextField:
            usernameOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        case phoneNumberTextField:
            phoneNumberOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        case passwordTextField:
            passwordOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
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
        case fullNameTextField:
            fullNameOuterView.borderColor = UIColor.gray.cgColor
        case usernameTextField:
            usernameOuterView.borderColor = UIColor.gray.cgColor
        case phoneNumberTextField:
            phoneNumberOuterView.borderColor = UIColor.gray.cgColor
        case passwordTextField:
            passwordOuterView.borderColor = UIColor.gray.cgColor
        default:
            confirmPasswordOuterView.borderColor = UIColor.gray.cgColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    
    @IBAction func signIn() {
        self.dismiss(animated: true, completion: nil)
    }

    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
