//
//  SignUpPageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 24.04.22.
//

import UIKit

class SignUpPageController: UIViewController {
    
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
    
    private let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
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
    
    func signUp(){
        print("BBBB")
    }
    
    @IBAction func signIn() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SignUpPageController: UITextFieldDelegate {
    
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == usernameTextField && string.contains(" ") { return false }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case fullNameTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            phoneNumberTextField.becomeFirstResponder()
        case phoneNumberTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            signUp()
        }
        
        return true
    }
    
}
