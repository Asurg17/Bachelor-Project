//
//  NewEventPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.09.22.
//

import UIKit
import JGProgressHUD

class NewEventPageVC: UIViewController {
    
    var toUserId: String?
    var groupId: String?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var eventNameTextField: UITextField!
    @IBOutlet var eventDescriptionTextField: UITextField!
    @IBOutlet var placeTextField: UITextField!
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var stackView: UIStackView!
    
    private var selectedDate = ""
    private var service = EventService()
    private let loader = JGProgressHUD()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "en_US_POSIX")
        picker.preferredDatePickerStyle = .wheels
        picker.minimumDate = Date()
        return picker
    }()
    
    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.locale = Locale(identifier: "en_GB_POSIX")
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        hideKeyboardWhenTappedAround()
        registerForKeyboardNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventNameTextField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stackView.layoutIfNeeded()
        placeTextField.addBottomBorder()
        dateTextField.addBottomBorder()
        timeTextField.addBottomBorder()
    }
    
    func setupViews() {
        eventNameTextField.delegate = self
        eventDescriptionTextField.delegate = self
        placeTextField.delegate = self
        dateTextField.delegate = self
        timeTextField.delegate = self
        
        let dtPicker = datePicker
        dtPicker.addTarget(self, action: #selector(dateHasChanged(datePicker:)), for: UIControl.Event.valueChanged)
        
        let tmPicker = timePicker
        tmPicker.addTarget(self, action: #selector(timeHasChanged(datePicker:)), for: UIControl.Event.valueChanged)
        
        dateTextField.inputView = dtPicker
        timeTextField.inputView = tmPicker
        
        dateTextField.text = formatDate(date: datePicker.date)
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
    
    func createNewEvent() {
        if chackIfallRequiredFieldsAreFilled() {
            guard let eventUniqueKey = createEventKey() else {
                showWarningAlert(warningText: "Can't create new event :(")
                return
            }
            
            var time = timeTextField.text ?? ""
            if time.isEmpty {
                time = "-:-"
            }
            
            if selectedDate.isEmpty { selectedDate = formatEventDate(date: Date()) }
            
            let parameters = [
                "userId": getUserId(),
                "groupId": getGroupId(),
                "eventName": eventNameTextField.text!,
                "eventDescription": eventDescriptionTextField.text ?? "",
                "place": placeTextField.text!,
                "date": dateTextField.text!,
                "time": time,
                "formattedDate": selectedDate,
                "eventUniqueKey": eventUniqueKey
            ]

            showLoader()
            service.createNewEvent(parameters: parameters) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.dismissLoader()
                    switch result {
                    case .success(_):
                        self.navigate(eventKey: eventUniqueKey, creatorId: self.getUserId(), groupId: self.getGroupId())
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.requiredFieldsAreNotFilledWarningText)
        }
    }
    
    func showLoader() {
        loader.textLabel.text = "Creating New Event..."
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    func dismissLoader() {
        UIView.animate(withDuration: 0.2, animations: {
            self.loader.textLabel.text = "Created"
            self.loader.detailTextLabel.text = nil
            self.loader.indicatorView = JGProgressHUDSuccessIndicatorView()
        })
                       
        loader.dismiss(animated: true)
    }
    
    func navigate(eventKey: String, creatorId: String, groupId: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "TasksPageStoryboard", bundle: nil)
        let tasksPageController = storyBoard.instantiateViewController(withIdentifier: "TasksPageVC") as! TasksPageVC
        tasksPageController.title = "Tasks"
        tasksPageController.eventKey = eventKey
        tasksPageController.creatorId = creatorId
        tasksPageController.groupId = groupId
        var array = navigationController?.viewControllers
        array?.removeLast()
        array?.append(tasksPageController)
        navigationController?.setViewControllers(array!, animated: true)
        
        //navigateToTasksPage(eventKey: eventKey, creatorId: creatorId, groupId: groupId)
    }
    
    func chackIfallRequiredFieldsAreFilled() -> Bool {
        if eventNameTextField.text == "" ||
            placeTextField.text == "" ||
            dateTextField.text == "" { return false }
        return true
    }
    
    private func createEventKey() -> String? {
        let dateString = GroupPageVC.dateFormatter.string(from: Date())
        let newIdentifier = "Event_\(getGroupId())_\(getUserId())_\(dateString)"

        return newIdentifier
    }
    
    @IBAction func buttonClicked() {
        createNewEvent()
    }
    
    @objc
    func dateHasChanged(datePicker: UIDatePicker) {
        selectedDate = formatEventDate(date: datePicker.date)
        dateTextField.text = formatDate(date: datePicker.date)
    }
    
    @objc
    func timeHasChanged(datePicker: UIDatePicker) {
        timeTextField.text = formatEventTime(date: datePicker.date)
    }
    
    @objc func keyboardWillChange(notification: NSNotification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else  {
            return
        }
    
        if notification.name == UIResponder.keyboardWillShowNotification
            || notification.name == UIResponder.keyboardWillChangeFrameNotification {

            let lastViewYCoordinate = stackView.frame.origin.y + stackView.frame.height

            if keyboardRect.origin.y < lastViewYCoordinate {
                view.frame.origin.y = keyboardRect.origin.y - lastViewYCoordinate - Constants.bottomOffset
            }
        } else {
            view.frame.origin.y = 0
        }
    }
}

extension NewEventPageVC: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if let text = textField.text,
           let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            if textField == eventNameTextField {
                if updatedText.count > Constants.eventNameCharactersMaxNum {
                    showWarningAlert(warningText: Constants.eventNameCharactersMaxNumWarning)
                    return false
                }
            }
            
            if textField == eventDescriptionTextField {
                if updatedText.count > Constants.eventDescriptionCharactersMaxNum {
                    showWarningAlert(warningText: Constants.eventDescriptionCharactersMaxNumWarning)
                    return false
                }
            }
            
            if textField == placeTextField {
                if updatedText.count > Constants.eventPlaceCharactersMaxNum {
                    showWarningAlert(warningText: Constants.eventPlaceCharactersMaxNumWarning)
                    return false
                }
            }
        }

        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case eventNameTextField:
            eventDescriptionTextField.becomeFirstResponder()
        case eventDescriptionTextField:
            placeTextField.becomeFirstResponder()
        case placeTextField:
            dateTextField.becomeFirstResponder()
        case dateTextField:
            timeTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            createNewEvent()
        }
        
        return true
    }
}
