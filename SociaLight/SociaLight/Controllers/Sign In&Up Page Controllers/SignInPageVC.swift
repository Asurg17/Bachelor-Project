//
//  ViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 05.04.22.
//

import UIKit
import CloudKit
import KeychainSwift

class SignInPageVC: UIViewController {
    
    @IBOutlet var usernameTextField: DesignableUITextField!
    @IBOutlet var passwordTextField: DesignableUITextField!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        registerForKeyboardNotifications()
        checkIfAlreadySignedIn()
    }
    
    func setupViews() {
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func checkIfAlreadySignedIn() {
        let keychain = KeychainSwift()
        if let _ = keychain.get(Constants.userIdKey) {
            navigateToMainPage()
        }
    }
    
    func signIn() {
        if checkIfAllViewsAreFilled() {
            if checkPasswordLength(password: passwordTextField.text!) {
                loader.startAnimating()
                service.checkUser(
                    username: usernameTextField.text!,
                    password: passwordTextField.text!
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
            }
        } else {
            showWarningAlert(warningText: Constants.fieldsAreNotFilledWarningText)
        }
    }
    
    func checkIfAllViewsAreFilled() -> Bool {
        if usernameTextField.text == "" || passwordTextField.text == "" { return false }
        return true
    }
    
    func handleSuccess(response: String) {
        clearAllTextFields()
        
        let keychain = KeychainSwift()
        keychain.set(response, forKey: Constants.userIdKey)
        
        navigateToMainPage()
    }
    
    func clearAllTextFields() {
        usernameTextField.text = ""
        passwordTextField.text = ""
    }
    
    
    @IBAction func signInToAccount() {
        signIn()
    }
    
    @IBAction func signUp() {
        navigateToSignUpPage()
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

extension SignInPageVC: UITextFieldDelegate {
    
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == usernameTextField && string.contains(" ") { return false }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField:
            passwordTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            signIn()
        }
        
        return true
    }
    
}
