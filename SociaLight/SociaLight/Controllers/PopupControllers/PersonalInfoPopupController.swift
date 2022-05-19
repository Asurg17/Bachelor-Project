//
//  PersonalInfoPopupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import UIKit
import KeychainSwift

class PersonalInfoPopupController: UIViewController {
    
    @IBOutlet var ageTextField: DesignableUITextField!
    @IBOutlet var phoneTextField: DesignableUITextField!
    @IBOutlet var birthDateTextField: DesignableUITextField!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    var delegate: DismissProtocol?
    
    private let service = Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        ageTextField.delegate = self
        phoneTextField.delegate = self
        birthDateTextField.delegate = self
        
        setupDatePicker()
        setCurrentUserInfo()
    }
    
    func setupDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(birthDateChange(datePicker:)), for: UIControl.Event.valueChanged)
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.frame.size = CGSize(width: 0, height: 150)
        datePicker.maximumDate = Date()
        
        birthDateTextField.inputView = datePicker
    }
    
    func setCurrentUserInfo() {
        if UserDefaults.standard.string(forKey: "user.age") != "-" {
            ageTextField.text = UserDefaults.standard.string(forKey: "user.age")
        }
        if UserDefaults.standard.string(forKey: "user.phone") != "-" {
            phoneTextField.text = UserDefaults.standard.string(forKey: "user.phone")
        }
        if UserDefaults.standard.string(forKey: "user.birthDate") != "-" {
            birthDateTextField.text = UserDefaults.standard.string(forKey: "user.birthDate")
        }
    }
    
    func saveChanges() {
        if checkForChanges() {
            let keychain = KeychainSwift()
            if let userId = keychain.get("userId") {
                loader.startAnimating()
                service.changePersonalInfo(
                    userId: userId,
                    age: ageTextField.text ?? "",
                    phoneNumber: phoneTextField.text ?? "",
                    birthDate: birthDateTextField.text ?? ""
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
                showWarningAlert(warningText: "Can't save Changes!")
            }
        } else {
            showWarningAlert(warningText: "Nothing to Change!")
        }
    }
    
    func checkForChanges() -> Bool {
        if ageTextField.text != UserDefaults.standard.string(forKey: "user.age") ||
           phoneTextField.text != UserDefaults.standard.string(forKey: "user.phone") ||
           birthDateTextField.text != UserDefaults.standard.string(forKey: "user.birthDate") { return true }
        return false
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
                    delegate?.refresh()
                    self.dismissPopup()
                }
            )
        )
        present(alert, animated: true, completion: nil)
    }
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? "Unspecified Error!")
    }
    
    @IBAction func saveMadeChanges() {
        saveChanges()
    }
    
    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc
    func birthDateChange(datePicker: UIDatePicker){
        birthDateTextField.text = formatDate(date: datePicker.date)
    }

}

extension PersonalInfoPopupController: UITextFieldDelegate {
    
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
        case ageTextField:
            birthDateTextField.becomeFirstResponder()
        case birthDateTextField:
            phoneTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            saveChanges()
        }
        return true
    }
}
