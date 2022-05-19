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
    
    func saveChanges() {
        
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
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            birthDateTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            saveChanges()
        }
        return true
    }
}
