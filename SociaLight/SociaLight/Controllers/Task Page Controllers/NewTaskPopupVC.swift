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
    @IBOutlet var taskTextField: UITextField!
    @IBOutlet var memberView: UIView!
    @IBOutlet var memberTextView: UITextField!
    @IBOutlet var button: UIButton!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private var assigneeId: String?
    private let menu = DropDown()
    private let service = TaskService()
    
    var eventKey: String?
    var members = [GroupMember]()
    var delegate: UpdateTasksProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkEventKey()
        setupViews()
        setupMenu()
        hideKeyboardWhenTappedAround()
        registerForKeyboardNotifications()
    }
    
    func checkEventKey() {
        if let _ = eventKey {} else {
            dismissPopup()
        }
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
        menu.anchorView = memberView
        menu.selectionAction = { index, title in
            self.assigneeId = self.members[index].memberId
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
        guard let assigneeId = assigneeId else {
            showWarningAlert(warningText: Constants.assigneeNotChosenWarningText)
            return
        }
        
        if let task = taskTextField.text {
            if task.replacingOccurrences(of: " ", with: "").isEmpty {
                showWarningAlert(warningText: Constants.requiredFieldsAreNotFilledWarningText)
                return
            } else {
                let parameters = [
                    "userId": getUserId(),
                    "assigneeId": assigneeId,
                    "eventUniqueKey": eventKey!,
                    "task": task
                ]
                
                loader.startAnimating()
                service.createNewTask(parameters: parameters) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.loader.stopAnimating()
                        switch result {
                        case .success(_):
                            self.dismissPopup()
                            self.delegate?.update()
                        case .failure(let error):
                            self.showWarningAlert(warningText: error.localizedDescription.description)
                        }
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.requiredFieldsAreNotFilledWarningText)
            return
        }
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
