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
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
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
    }
    
    func registerClient(){
        if checkIfAllViewsAreFilled() {
            if checkIfPasswordsMatches(pass1: passwordTextField.text!,
                                       pass2: confirmPasswordTextField.text!) {
                if checkPasswordLength(password: passwordTextField.text!) {
                    loader.startAnimating()
                    service.registerNewUser(
                        username: usernameTextField.text!,
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
                                self.handleError(error: error.localizedDescription.description)
                            }
                        }
                    }
                }
            }
        } else {
            showWarningAlert(warningText: "Please fill all the fields!")
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
    
    func checkIfPasswordsMatches() -> Bool {
        return passwordTextField.text == confirmPasswordTextField.text
    }
    
    func handleSuccess(response: String) {
        clearAllTextFields()
        
        let keychain = KeychainSwift()
        keychain.set(response, forKey: "userId")
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signUpPageController = storyBoard.instantiateViewController(withIdentifier: "MainPage") as! UITabBarController
        self.navigationController?.pushViewController(signUpPageController, animated: true)
    }
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? "Unspecified Error!")
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
        self.dismiss(animated: true, completion: nil)
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
        if textField == usernameTextField && string.contains(" ") { return false }
        if textField == phoneNumberTextField && !checkIfContainsOnlyNumbers(str: string) { return false }
        return true
    }
    
    func checkIfContainsOnlyNumbers(str: String) -> Bool {
        if (str == "") { return true }
        let digitCharacters = CharacterSet.decimalDigits
        return str.rangeOfCharacter(from: digitCharacters) != nil
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
