//
//  NewTaskPopupVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.09.22.
//

import UIKit
import DropDown

class NewTaskPopupVC: UIViewController {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var memberTextView: UITextField!
    @IBOutlet var button: UIButton!
    
    private let menu = DropDown()
    
    var members = [GroupMember]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupMenu()
        hideKeyboardWhenTappedAround()
        registerForKeyboardNotifications()
    }
    
    func setupViews() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMemberView))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        memberTextView.addGestureRecognizer(gesture)
    }
    
    func setupMenu() {
        var membersArr = [String]()
        for member in members {
            membersArr.append("\(member.memberFirstName) \(member.memberLastName)")
        }
        
        menu.dataSource = membersArr
        menu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        menu.customCellConfiguration = { index, title, cell in
            guard let cell = cell as? CustomDropDownCell else {
                return
            }
            cell.configure(with: self.members[index].memberId)
        }
        menu.anchorView = memberTextView
        menu.selectionAction = { index, title in
            self.memberTextView.text = title
        }
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
    
    @IBAction func asignTask() {
//        saveChanges()
    }
    
    @IBAction func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapMemberView() {
        menu.show()
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
