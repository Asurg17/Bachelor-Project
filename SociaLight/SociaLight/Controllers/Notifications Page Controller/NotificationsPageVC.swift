//
//  NotificationsPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 08.08.22.
//

import UIKit
import JGProgressHUD

class NotificationsSection {
    
    var id: String
    var header: NotificationHeaderModel?
    var notifications = [NotificationCellModel]()
    
    var numberOfRows: Int {
        return notifications.count
    }
      
    init(id: String, header: NotificationHeaderModel?, notifications: [NotificationCellModel]) {
        self.id = id
        self.header = header
        self.notifications = notifications
    }
    
}

class NotificationsPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningText: UILabel!
    
    private let service = NotificationService()
    private var tableData = [NotificationsSection]()
    private let refreshControl = UIRefreshControl()
    private var loader = JGProgressHUD()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotifications()
    }
    
    func setupViews() {
        configureTableView()
    }
    
    func configureTableView() {
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 20
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        
        tableView.layoutMargins.left = 0.1
        tableView.layoutMargins.right = 0.1
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.tableRowHeight + Constants.tableViewOffset, bottom: 0, right: Constants.tableViewOffset)

        tableView.register(
            UINib(nibName: "NotificationCell", bundle: nil),
            forCellReuseIdentifier: "NotificationCell"
        )
        
        tableView.register(
            UINib(nibName: "NotificationHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "NotificationHeader"
        )
    }
    
    func clearTable() {
        tableData = []
        tableView.reloadData()
    }
    
    func getNotifications() {
        let userId = getUserId()
        
        showLoader(text: "Loading...")
        service.getUserNotifications(userId: userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.dismiss(animated: true)
                self.refreshControl.endRefreshing()
                switch result {
                case .success(let response):
                    self.clearTable()
                    self.handleSuccess(response: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(response: Notifications) {
        for notification in response.notifications {
            
            let id = notification.sendDate
            
            let notificationCellModel =  NotificationCellModel(
                requestUniqueKey: notification.requestUniqueKey,
                fromUserId: notification.fromUserId,
                notificationTitle: notification.notificationTitle,
                notificationText: notification.notificationText,
                notificationType: notification.notificationType,
                groupId: notification.groupId,
                groupTitle: notification.groupTitle,
                groupDescription: notification.groupDescription,
                groupCapacity: notification.groupCapacity,
                membersCount: notification.membersCount,
                sendDate: notification.sendDate,
                sendTime: notification.sendTime,
                delegate: self
            )
            
            if let sectionIndex = tableData.firstIndex(where: { $0.id == id }) {
                tableData[sectionIndex].notifications.append(notificationCellModel)
                
//                tableView.beginUpdates()
//                tableView.reloadSections(IndexSet(integer: sectionIndex), with: .fade)
//                tableView.endUpdates()
            
            } else {
                
                let section = NotificationsSection(
                    id: id,
                    header: NotificationHeaderModel(title: id),
                    notifications: [notificationCellModel]
                )
                
                tableData.append(section)
                
//                tableView.beginUpdates()
//                tableView.insertSections(IndexSet(integer: tableData.count-1), with: .fade)
//                tableView.endUpdates()
            }
            tableView.reloadData()
        }
    }
    
    func removeFromTable(elem: NotificationCellModel) {
        for section in 0...tableData.count-1 {
            if let row = tableData[section].notifications.firstIndex(where: { $0.requestUniqueKey == elem.requestUniqueKey && $0.notificationType == elem.notificationType }) {
                let indexPath = IndexPath(row: row, section: section)
                
                if tableData[indexPath.section].notifications.count == 1 {
                    tableData.remove(at: indexPath.section)
        
                    tableView.beginUpdates()
                    tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                    tableView.endUpdates()
                } else {
                    tableData[indexPath.section].notifications.remove(at: indexPath.row)
        
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    tableView.endUpdates()
                }
                
                return
            }
        }
    }
    
    func showLoader(text: String) {
        loader = JGProgressHUD()
        loader.textLabel.text = text
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    func dismissLoader() {
        UIView.animate(withDuration: 0.2, animations: {
            self.loader.textLabel.text = "Success"
            self.loader.detailTextLabel.text = nil
            self.loader.indicatorView = JGProgressHUDSuccessIndicatorView()
        })
                       
        loader.dismiss(animated: true)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getNotifications()
    }

}

extension NotificationsPageVC: NotificationCellDelegate {

    func friendshipAccepted(_ notification: NotificationCell) {
        let userId = getUserId()
            
        showLoader(text: "Processing...")
        service.acceptFriendshipRequest(userId: userId, fromUserId: notification.model.fromUserId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dismissLoader()
                switch result {
                case .success(_):
                    self.removeFromTable(elem: notification.model)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                    notification.enableButtons()
                }
            }
        }
    }
    
    func friendshipRejected(_ notification: NotificationCell) {
        let userId = getUserId()
        
        showLoader(text: "Processing...")
        service.rejectFriendshipRequest(userId: userId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dismissLoader()
                switch result {
                case .success(_):
                    self.removeFromTable(elem: notification.model)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                    notification.enableButtons()
                }
            }
        }
    }
        
    func acceptInvitation(_ notification: NotificationCell) {
        let userId = getUserId()
        
        showLoader(text: "Processing...")
        service.acceptInvitation(userId: userId, fromUserId: notification.model.fromUserId, groupId: notification.model.groupId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dismissLoader()
                switch result {
                case .success(_):
                    self.removeFromTable(elem: notification.model)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                    notification.enableButtons()
                }
            }
        }
    }

    func rejectInvitation(_ notification: NotificationCell) {
        let userId = getUserId()
        
        showLoader(text: "Processing...")
        service.rejectInvitation(userId: userId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dismissLoader()
                switch result {
                case .success(_):
                    self.removeFromTable(elem: notification.model)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                    notification.enableButtons()
                }
            }
        }
    }
    
    func navigateToUserPage(userId: String) {
        navigateToUserProfilePage(userId: userId)
    }
    
    func navigateToGroupPage(groupId: String) {
        navigateToGroupPage(groupId: groupId, isUserGroupMember: false)
    }
    
}


extension NotificationsPageVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableData.isEmpty { warningText.isHidden = false } else { warningText.isHidden = true }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].numberOfRows
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerModel = tableData[section].header else { return nil}
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NotificationHeader")
        
        if let notificationHeader = header as? NotificationHeader {
            notificationHeader.configure(with: headerModel)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NotificationCell",
            for: indexPath
        )
        
        if let notificationCell = cell as? NotificationCell {
            notificationCell.configure(with: tableData[indexPath.section].notifications[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
}

