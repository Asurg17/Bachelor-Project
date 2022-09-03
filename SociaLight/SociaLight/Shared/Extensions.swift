//
//  Extensions.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.04.22.
//

import UIKit
import MessageKit
import KeychainSwift
import AVFoundation

extension UIViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy HH:mm:ss.SSS"
        return formatter
    }()
    
    func getDateString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        switch true {
        case Calendar.current.isDateInToday(date) || Calendar.current.isDateInYesterday(date):
            formatter.doesRelativeDateFormatting = true
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear):
            formatter.dateFormat = "EEEE"
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year):
            formatter.dateFormat = "E, d MMM"
        default:
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }
    
    func getTimeString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let time = formatter.string(from: date)
        return time
    }
    
    // ------------Shared Functions-----------
    
    func getUserId() -> String {
        let keychain = KeychainSwift()
        if let userId = keychain.get(Constants.userIdKey) {
            return userId
        } else {
            fatalError(Constants.fatalError)
        }
    }
    
    func getGroupId() -> String {
        if let groupId = UserDefaults.standard.string(forKey: Constants.groupIdKey){
            return groupId
        } else {
            fatalError(Constants.fatalError)
        }
    }
    
    func showWarningAlert(warningText: String?) {
        let alert = UIAlertController(
            title: "Warning",
            message: warningText ?? Constants.unspecifiedWarningText,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: .default,
                handler: nil
            )
        )
        present(alert, animated: true, completion: nil)
    }
    
    func showWarningAlertWithHandler(warningText: String) {
        let alert = UIAlertController(
            title: "Warning",
            message: warningText,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: .default,
                handler: { [unowned self] _ in
                    self.navigationController?.popToRootViewController(animated: true)
                }
            )
        )
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleError(errorText: String?) -> ErrorView {
        let screenSize: CGRect = UIScreen.main.bounds
        let myView = ErrorView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: screenSize.width,
                height: screenSize.height
            )
        )
        myView.errorLabel.text = errorText ?? Constants.unspecifiedErrorText
        self.view.addSubview(myView)
        
        return myView
    }

    func checkIfPasswordsMatches(pass1: String, pass2: String) -> Bool {
        if (pass1 == pass2) {
            return true
        } else {
            return false
        }
    }
    
    func checkPasswordLength(password: String) -> Bool {
        if password.count < 6 {
            return false
        }
        return true
    }
    
    func isGroupValid(group: Group?) -> Bool{
        guard let _ = group else {
            return false
        }
        return true
    }
    
    func checkIfContainsOnlyNumbers(str: String) -> Bool {
        if (str == "") { return true }
        let digitCharacters = CharacterSet.decimalDigits
        return str.rangeOfCharacter(from: digitCharacters) != nil
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func formatEventDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func formatEventTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Navigation
    
    func navigateToSignUpPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signUpPageController = storyBoard.instantiateViewController(withIdentifier: "SignUpPageVC") as! SignUpPageVC
        self.navigationController?.pushViewController(signUpPageController, animated: true)
    }
    
    func navigateToMainPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyBoard.instantiateViewController(withIdentifier: "MainPage") as! UITabBarController
        self.navigationController?.pushViewController(tabBarController, animated: true)
    }
    
    func navigateToFindGroupPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let findGroupController = storyBoard.instantiateViewController(withIdentifier: "FindGroupPageVC") as! FindGroupPageVC
        self.navigationController?.pushViewController(findGroupController, animated: true)
    }
    
    func navigateToNewGroupPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newGroupControlles = storyBoard.instantiateViewController(withIdentifier: "NewGroupFirstPageVC") as! NewGroupFirstPageVC
        self.navigationController?.pushViewController(newGroupControlles, animated: true)
    }
    
    func navigateToNewGroupSecondVC(group: Group) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newGroupSecondPageController = storyBoard.instantiateViewController(withIdentifier: "NewGroupSecondPageVC") as! NewGroupSecondPageVC
        newGroupSecondPageController.group = group
        self.navigationController?.pushViewController(newGroupSecondPageController, animated: true)
    }
    
    func navigateToGroupPage(groupId: String, isUserGroupMember: Bool) {
        UserDefaults.standard.set(groupId, forKey: Constants.groupIdKey)
        UserDefaults.standard.set(isUserGroupMember, forKey: "isUserGroupMember")
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupPageController = storyBoard.instantiateViewController(withIdentifier: "GroupPageVC") as! GroupPageVC
        self.navigationController?.pushViewController(groupPageController, animated: true)
    }
    
    func navigateToGrouInfoPage(vc: GroupPageVC) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupInfoPagePageController = storyBoard.instantiateViewController(withIdentifier: "GroupInfoPageVC") as! GroupInfoPageVC
        groupInfoPagePageController.delegate = vc
        groupInfoPagePageController.title = ""
        self.navigationController?.pushViewController(groupInfoPagePageController, animated: true)
    }
    
    func navigateToGroupMembersPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupMembersPageController = storyBoard.instantiateViewController(withIdentifier: "GroupMembersPageVC") as! GroupMembersPageVC
        groupMembersPageController.title = "Group Members"
        self.navigationController?.pushViewController(groupMembersPageController, animated: true)
    }
    
    func navigateToGroupMediaFilesPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupMediaFilesPageController = storyBoard.instantiateViewController(withIdentifier: "GroupMediaFilesPageVC") as! GroupMediaFilesPageVC
        groupMediaFilesPageController.title = "Group Media Files"
        self.navigationController?.pushViewController(groupMediaFilesPageController, animated: true)
    }
    
    func navigateToAddGroupMembersPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addGroupMembersPageController = storyBoard.instantiateViewController(withIdentifier: "AddGroupMembersPageVC") as! AddGroupMembersPageVC
        addGroupMembersPageController.title = "Add Group Members"
        self.navigationController?.pushViewController(addGroupMembersPageController, animated: true)
    }
    
    func navigateToImagePage(url: URL) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "ImagePageStoryboard", bundle: nil)
        let imagePageController = storyBoard.instantiateViewController(withIdentifier: "ImagePageVC") as! ImagePageVC
        imagePageController.url = url
        self.navigationController?.pushViewController(imagePageController, animated: true)
    }
    
    func navigateToUserProfilePage(userId: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let userProfilePageController = storyBoard.instantiateViewController(withIdentifier: "ProfilePageVC") as! ProfilePageVC
        userProfilePageController.currUserId = userId
        userProfilePageController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(userProfilePageController, animated: true)
    }
    
    func navigateToFriendsPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "FriendsPageStoryboard", bundle: nil)
        let friendsPageController = storyBoard.instantiateViewController(withIdentifier: "FriendsPageVC") as! FriendsPageVC
        friendsPageController.title = "Friends"
        friendsPageController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(friendsPageController, animated: true)
    }
    
    func navigateToSearchNewFriendsPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "FriendsSearchPageStoryboard", bundle: nil)
        let searchNewFriendsPageController = storyBoard.instantiateViewController(withIdentifier: "FriendsSearchPageVC") as! FriendsSearchPageVC
        searchNewFriendsPageController.title = "Search New Friends"
        searchNewFriendsPageController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(searchNewFriendsPageController, animated: true)
    }
    
    func navigateToSendMeetingInvitationPopupPage() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let sendMeetingInvitatioPopupPageController = storyboard.instantiateViewController(withIdentifier: "SendMeetingInvitationPopupVC") as! SendMeetingInvitationPopupVC
        sendMeetingInvitatioPopupPageController.providesPresentationContextTransitionStyle = true
        sendMeetingInvitatioPopupPageController.definesPresentationContext = true
        sendMeetingInvitatioPopupPageController.modalPresentationStyle = .overFullScreen
        sendMeetingInvitatioPopupPageController.modalTransitionStyle = .crossDissolve
        self.navigationController?.present(sendMeetingInvitatioPopupPageController, animated: true)
    }
    
    func navigateToPersonalInfoPopupPage(vc: ProfilePageVC) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let personalInfoPopupPageController = storyboard.instantiateViewController(withIdentifier: "PersonalInfoPopupVC") as! PersonalInfoPopupVC
        personalInfoPopupPageController.providesPresentationContextTransitionStyle = true
        personalInfoPopupPageController.definesPresentationContext = true
        personalInfoPopupPageController.modalPresentationStyle = .overFullScreen
        personalInfoPopupPageController.modalTransitionStyle = .crossDissolve
        personalInfoPopupPageController.delegate = vc
        self.navigationController?.present(personalInfoPopupPageController, animated: true)
    }

    func navigateToChangePasswordPopupPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let changePasswordPopupPageController = storyBoard.instantiateViewController(withIdentifier: "ChangePasswordPopupVC") as! ChangePasswordPopupVC
        changePasswordPopupPageController.providesPresentationContextTransitionStyle = true
        changePasswordPopupPageController.definesPresentationContext = true
        changePasswordPopupPageController.modalPresentationStyle = .overFullScreen
        changePasswordPopupPageController.modalTransitionStyle = .crossDissolve
        self.navigationController?.present(changePasswordPopupPageController, animated: true)
    }
    
    func navigateToNewEventPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "NewEventPageStoryboard", bundle: nil)
        let newEventPageController = storyBoard.instantiateViewController(withIdentifier: "NewEventPageVC") as! NewEventPageVC
        newEventPageController.title = "New Event"
        self.navigationController?.pushViewController(newEventPageController, animated: true)
    }
    
    func navigateToEventPage(eventKey: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "EventPageStoryboard", bundle: nil)
        let eventPageController = storyBoard.instantiateViewController(withIdentifier: "EventPageVC") as! EventPageVC
        eventPageController.title = "Event"
        eventPageController.eventKey = eventKey
        eventPageController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(eventPageController, animated: true)
    }
    
    func navigateToEventsPage() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let eventsPageController = storyBoard.instantiateViewController(withIdentifier: "EventsPageVC") as! EventsPageVC
        eventsPageController.title = "Event"
        eventsPageController.groupId = getGroupId()
        self.navigationController?.pushViewController(eventsPageController, animated: true)
    }
    
    func navigateToTasksPage(eventKey: String, creatorId: String, groupId: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "TasksPageStoryboard", bundle: nil)
        let tasksPageController = storyBoard.instantiateViewController(withIdentifier: "TasksPageVC") as! TasksPageVC
        tasksPageController.title = "Tasks"
        tasksPageController.eventKey = eventKey
        tasksPageController.creatorId = creatorId
        tasksPageController.groupId = groupId
        self.navigationController?.pushViewController(tasksPageController, animated: true)
    }
    
    func navigateToNewTaskPopupVC(members: [GroupMember], eventKey: String, vc: TasksPageVC) {
        let storyboard: UIStoryboard = UIStoryboard(name: "TasksPageStoryboard", bundle: nil)
        let newTaskPopupController = storyboard.instantiateViewController(withIdentifier: "NewTaskPopupVC") as! NewTaskPopupVC
        newTaskPopupController.providesPresentationContextTransitionStyle = true
        newTaskPopupController.definesPresentationContext = true
        newTaskPopupController.modalPresentationStyle = .overCurrentContext
        newTaskPopupController.modalTransitionStyle = .crossDissolve
        newTaskPopupController.members = members
        newTaskPopupController.eventKey = eventKey
        newTaskPopupController.delegate = vc
        self.navigationController?.present(newTaskPopupController, animated: true)
    }
    
    // Check access
    
    func checkCameraAccess() -> Bool {
       switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                ()
            }
            return false
       case .denied, .restricted:
            showWarningAlert(warningText: "Please go to setting and allow camera access!")
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }
    
    func checkMicrophoneAccess() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            showWarningAlert(warningText: "Please go to setting and allow microphone access!")
            return false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                ()
            })
            return false
        @unknown default:
            return false
        }
    }
}

extension UINavigationController {
    func popToViewController(ofClass: AnyClass, animated: Bool = true) {
        if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
            popToViewController(vc, animated: animated)
        }
    }
}

extension UITextField {
    func addBottomBorder(){
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: self.frame.size.width, height: 1)
        bottomLine.backgroundColor = UIColor.darkGray.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
}

extension UILabel {
    func addBottomBorder(){
        let bottomLayer = CALayer()
        bottomLayer.frame = CGRect(x: 0, y: frame.height - 2, width: frame.width, height: 1)
        bottomLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(bottomLayer)
    }
}

extension UIRefreshControl {
    func refreshManually() {
        beginRefreshing()
        sendActions(for: .valueChanged)
    }
}

extension UIColor {
    
    static func random() -> UIColor {
        return UIColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    
    struct FlatColor {
        
        struct Green {
            static let Fern = UIColor(netHex: 0x6ABB72)
            static let MountainMeadow = UIColor(netHex: 0x3ABB9D)
            static let ChateauGreen = UIColor(netHex: 0x4DA664)
            static let PersianGreen = UIColor(netHex: 0x2CA786)
        }
        
        struct Blue {
            static let PictonBlue = UIColor(netHex: 0x5CADCF)
            static let Mariner = UIColor(netHex: 0x3585C5)
            static let CuriousBlue = UIColor(netHex: 0x4590B6)
            static let Denim = UIColor(netHex: 0x2F6CAD)
            static let Chambray = UIColor(netHex: 0x485675)
            static let BlueWhale = UIColor(netHex: 0x29334D)
        }
        
        struct Violet {
            static let Wisteria = UIColor(netHex: 0x9069B5)
            static let BlueGem = UIColor(netHex: 0x533D7F)
        }
        
        struct Yellow {
            static let Energy = UIColor(netHex: 0xF2D46F)
            static let Turbo = UIColor(netHex: 0xF7C23E)
        }
        
        struct Orange {
            static let NeonCarrot = UIColor(netHex: 0xF79E3D)
            static let Sun = UIColor(netHex: 0xEE7841)
        }
        
        struct Red {
            static let TerraCotta = UIColor(netHex: 0xE66B5B)
            static let Valencia = UIColor(netHex: 0xCC4846)
            static let Cinnabar = UIColor(netHex: 0xDC5047)
            static let WellRead = UIColor(netHex: 0xB33234)
        }
        
        struct Gray {
            static let AlmondFrost = UIColor(netHex: 0xA28F85)
            static let WhiteSmoke = UIColor(netHex: 0xEFEFEF)
            static let Iron = UIColor(netHex: 0xD1D5D8)
            static let IronGray = UIColor(netHex: 0x75706B)
        }
    }
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension String {
    var boolValue: Bool {
        return (self as NSString).boolValue
    }
}

extension Collection where Indices.Iterator.Element == Index {
   public subscript(safe index: Index) -> Iterator.Element? {
     return (startIndex <= index && index < endIndex) ? self[index] : nil
   }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIImage {
    func toPngString() -> String? {
        let data = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
  
    func toJpegString(compressionQuality cq: CGFloat) -> String? {
        let data = self.jpegData(compressionQuality: cq)
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

extension MessageKind {
    var description: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

enum ServiceError: Error {
    case noData
    case invalidParameters
}
