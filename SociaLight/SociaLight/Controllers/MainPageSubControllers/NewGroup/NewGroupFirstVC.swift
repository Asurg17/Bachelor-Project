//
//  NewGroupVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 13.06.22.
//

import UIKit
import KeychainSwift

class NewGroupFirstVC: UIViewController {
    
    @IBOutlet var imageOuterView: UIView!
    @IBOutlet var membersCount: UIButton!
    @IBOutlet var groupName: UITextField!
    @IBOutlet var groupDescription: UITextField!
    
    var pickerView: UIPickerView!
    var pickerData = [2, 3, 4, 5, 10, 20, 25, 50]
    var pickerValue: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageOuterView.layer.borderWidth = 2
        imageOuterView.layer.borderColor = UIColor(hexString: "#2a2727").cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let receiverVC = segue.destination as! NewGroupSecondVC
        receiverVC.image = ""
        receiverVC.membersCount = pickerValue
        receiverVC.groupName = groupName.text
        receiverVC.groupDescription = groupDescription.text
    }
    
    func setupViews() {
        groupName.delegate = self
        groupDescription.delegate = self
    }

    
    @IBAction func showPicker() {
        pickerView = UIPickerView(frame: CGRect(x: 10, y: 50, width: 250, height: 150))
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let picker = UIAlertController(title: "Members Count", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        picker.view.addSubview(pickerView)
        picker.addAction(
            UIAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                    self.pickerValue = self.pickerData[self.pickerView.selectedRow(inComponent: 0)]
                    self.membersCount.setTitle(
                        "Members Count (" + String(self.pickerValue ?? 0) + ")",
                        for: .normal
                    )
                }
            )
        )
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(picker, animated: true)
    }
    
    @IBAction func back() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewGroupFirstVC: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(pickerData[row])
    }
    
}

extension NewGroupFirstVC: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
}

extension NewGroupFirstVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case groupName:
            groupDescription.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

