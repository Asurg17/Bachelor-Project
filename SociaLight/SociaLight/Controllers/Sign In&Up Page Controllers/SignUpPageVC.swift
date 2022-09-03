//
//  SignUpPageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 24.04.22.
//

import UIKit
import KeychainSwift

class SignUpPageVC: UIViewController {
    
    @IBOutlet var fullNameTextField:        DesignableUITextField!
    @IBOutlet var usernameTextField:        DesignableUITextField!
    @IBOutlet var phoneNumberTextField:     DesignableUITextField!
    @IBOutlet var passwordTextField:        DesignableUITextField!
    @IBOutlet var confirmPasswordTextField: DesignableUITextField!
    
    @IBOutlet var button: UIButton!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = SignInUpService()

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
        fullNameTextField.delegate = self
        usernameTextField.delegate = self
        phoneNumberTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    func registerClient(){
        if checkIfAllViewsAreFilled() {
            if checkIfPasswordsMatches(pass1: passwordTextField.text!,
                                       pass2: confirmPasswordTextField.text!) {
                if checkPasswordLength(password: passwordTextField.text!) {
                    loader.startAnimating()
                    button.isEnabled = false
                    service.registerNewUser(
                        username: usernameTextField.text!.lowercased(),
                        firstName: getFirstName(),
                        lastName: getLastName(),
                        phoneNumber: phoneNumberTextField.text!,
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
                            self.button.isEnabled = true
                        }
                    }
                } else {
                    showWarningAlert(warningText: Constants.passwordLengthWarningText)
                }
            } else {
                showWarningAlert(warningText: Constants.passwordDoesNotMatchWarningText)
            }
        } else {
            showWarningAlert(warningText: Constants.fieldsAreNotFilledWarningText)
        }
    }
    
    func getFirstName() -> String {
        return fullNameTextField.text!.components(separatedBy: " ")[0]
    }
    
    func getLastName() -> String {
        let words = fullNameTextField.text!.components(separatedBy: " ")
        return words[1..<words.count].joined(separator: " ")
    }
    
    func checkIfAllViewsAreFilled() -> Bool {
        if fullNameTextField.text         == "" ||
           usernameTextField.text         == "" ||
           phoneNumberTextField.text      == "" ||
           passwordTextField.text         == "" ||
           confirmPasswordTextField.text  == "" { return false }
        return true
    }
    
    func handleSuccess(response: String) {
        clearAllTextFields()
        
        let keychain = KeychainSwift()
        keychain.set(response, forKey: Constants.userIdKey)
        
        navigateToMainPage()
    }
    
    func clearAllTextFields() {
        fullNameTextField.text = ""
        usernameTextField.text = ""
        phoneNumberTextField.text = ""
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
    }
    
    @IBAction func signUp() {
        registerClient()
    }
    
    @IBAction func signIn() {
        navigationController?.popViewController(animated: true)
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

extension SignUpPageVC: UITextFieldDelegate {
    
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
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            if textField == fullNameTextField {
                if updatedText.prefix(1) == " " {
                    return false
                }
            
                let components = updatedText.components(separatedBy: " ")

                let firstName = components[0]
                let lastName = components[1..<components.count].joined(separator: " ")
                
                if firstName.count > Constants.firstNameCharactersMaxNum {
                    showWarningAlert(warningText: Constants.firstNameCharactersMaxNumWarning)
                    return false
                }
                
                if lastName.count > Constants.lastNameCharactersMaxNum {
                    showWarningAlert(warningText: Constants.lastNameCharactersMaxNumWarning)
                    return false
                }
            }
            
            if textField == usernameTextField {
                if updatedText.contains(" ") { return false }
                if updatedText.count > Constants.usernameCharactersMaxNum {
                    showWarningAlert(warningText: Constants.usernameCharactersMaxNumWarning)
                    return false
                }
            }
            
            if textField == phoneNumberTextField {
                if !checkIfContainsOnlyNumbers(str: updatedText) { return false }
                if updatedText.count > Constants.phoneCharactersMaxNum {
                    showWarningAlert(warningText: Constants.phoneCharactersMaxNumWarning)
                    return false
                }
            }
        
        }
        
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
            registerClient()
        }
        
        return true
    }
    
}
