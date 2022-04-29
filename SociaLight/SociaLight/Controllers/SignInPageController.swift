//
//  ViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 05.04.22.
//

import UIKit

class SignInPageController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var usernameOuterView: CustomTextFieldOuterView!
    @IBOutlet var passwordOuterView: CustomTextFieldOuterView!
    
    @IBOutlet var usernameTextField: DesignableUITextField!
    @IBOutlet var passwordTextField: DesignableUITextField!
    
    @IBOutlet var logInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
        setupViews()
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func setupViews() {
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        logInButton.layer.cornerRadius = logInButton.frame.size.height / 3
        logInButton.clipsToBounds = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.FlatColor.Blue.Mariner
            field.color = UIColor.FlatColor.Blue.Mariner
        }
        
        if textField == usernameTextField {
            usernameOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        } else {
            passwordOuterView.borderColor = UIColor.FlatColor.Blue.Mariner.cgColor
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let field = textField as? DesignableUITextField {
            field.textColor = UIColor.lightGray
            field.color = UIColor.lightGray
        }
        
        if textField == usernameTextField {
            usernameOuterView.borderColor = UIColor.gray.cgColor
        } else {
            passwordOuterView.borderColor = UIColor.gray.cgColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    @IBAction func signUp() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signUpPageController = storyBoard.instantiateViewController(withIdentifier: "SignUpPage") as! UINavigationController
        self.navigationController?.present(signUpPageController, animated: true)
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

