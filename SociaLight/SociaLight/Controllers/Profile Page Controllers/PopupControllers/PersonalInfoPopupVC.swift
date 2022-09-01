//
//  PersonalInfoPopupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import UIKit

class PersonalInfoPopupVC: UIViewController {
    
    @IBOutlet var phoneTextField: DesignableUITextField!
    @IBOutlet var birthDateTextField: DesignableUITextField!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var button: UIButton!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    var delegate: DismissProtocol?
    
    private let datePicker = UIDatePicker()
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
        phoneTextField.delegate = self
        birthDateTextField.delegate = self
        
        setupDatePicker()
        setCurrentUserInfo()
    }
    
    func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(birthDateChange(datePicker:)), for: UIControl.Event.valueChanged)
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Date()
        datePicker.locale = Locale(identifier: "en_US_POSIX")
        birthDateTextField.inputView = datePicker
    }
    
    func setCurrentUserInfo() {
        if UserDefaults.standard.string(forKey: "user.phone") != "-" {
            phoneTextField.text = UserDefaults.standard.string(forKey: "user.phone")
        }
        if UserDefaults.standard.string(forKey: "user.birthDate") != "-" {
            birthDateTextField.text = UserDefaults.standard.string(forKey: "user.birthDate")
        } else {
            birthDateTextField.text = formatDate(date: datePicker.date)
        }
    }
    
    func saveChanges() {
        if checkForChanges() {
            let userId = getUserId()
                
            loader.startAnimating()
            button.isEnabled = false
            service.changePersonalInfo(
                userId: userId,
                age: getUserAge(),
                phoneNumber: phoneTextField.text ?? "",
                birthDate: birthDateTextField.text ?? ""
            ) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.delegate?.refresh()
                        self.dismissPopup()
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                    self.button.isEnabled = true
                }
            }
        } else {
            showWarningAlert(warningText: Constants.noChangesdWarningText)
        }
    }
    
    func checkForChanges() -> Bool {
        if phoneTextField.text != UserDefaults.standard.string(forKey: "user.phone") ||
           birthDateTextField.text != UserDefaults.standard.string(forKey: "user.birthDate") { return true }
        return false
    }
    
    func getUserAge() -> String {
        let calendar = Calendar.current
        let startComponents = datePicker.date
        let endComponents = Date()

        let dateComponents = calendar.dateComponents([.year], from: startComponents, to: endComponents)
        
        return dateComponents.year?.description ?? ""
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

extension PersonalInfoPopupVC: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            if textField == phoneTextField {
                if !checkIfContainsOnlyNumbers(str: updatedText) { return false }
                if updatedText.count > Constants.phoneCharactersMaxNum {
                    showWarningAlert(warningText: Constants.phoneCharactersMaxNumWarning)
                    return false
                }
            }
        }
        return true
    }
    
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
        case birthDateTextField:
            phoneTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            saveChanges()
        }
        return true
    }
}
