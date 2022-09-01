//
//  SendMeetingInvitationPopupVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 28.08.22.
//

import UIKit

class SendMeetingInvitationPopupVC: UIViewController {
    
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    var delegate: DismissProtocol?
    
    private let datePicker = UIDatePicker()
    private let service = Service()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
    }
    
    

    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }

}

extension SendMeetingInvitationPopupVC: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let _ = text.replacingCharacters(in: textRange, with: string)
            
//            if textField == phoneTextField {
//                if !checkIfContainsOnlyNumbers(str: updatedText) { return false }
//                if updatedText.count > Constants.phoneCharactersMaxNum {
//                    showWarningAlert(warningText: Constants.phoneCharactersMaxNumWarning)
//                    return false
//                }
//            }
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
//        switch textField {
//        case birthDateTextField:
//            phoneTextField.becomeFirstResponder()
//        default:
//            textField.resignFirstResponder()
//            saveChanges()
//        }
        return true
    }
}
