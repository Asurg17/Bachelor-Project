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
    
    @IBOutlet var button: UIButton!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfAlreadySignedIn()
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
        usernameTextField.delegate = self
        passwordTextField.delegate = self
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
                service.validateUser(
                    username: usernameTextField.text!.lowercased(),
                    password: passwordTextField.text!
                ) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.loader.stopAnimating()
                        switch result {
                        case .success(let response):
                            self.handleSuccess(response: response)
                        case .failure(let error):
                            self.showWarningAlert(warningText: error.localizedDescription.description)
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
        if usernameTextField.isFirstResponder { usernameTextField.resignFirstResponder() }
        if passwordTextField.isFirstResponder { passwordTextField.resignFirstResponder() }
        navigateToSignUpPage()
    }
    
    @objc func keyboardWillChange(notification: NSNotification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else  {
            return
        }
    
        if notification.name == UIResponder.keyboardWillShowNotification
            || notification.name == UIResponder.keyboardWillChangeFrameNotification {

            let lastViewYCoordinate = button.frame.origin.y + button.frame.height
            
            if keyboardRect.origin.y < lastViewYCoordinate {
                view.frame.origin.y = keyboardRect.origin.y - lastViewYCoordinate - Constants.bottomOffset
            }
        } else {
            view.frame.origin.y = 0
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
