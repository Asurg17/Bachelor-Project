//
//  NotificationPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 08.08.22.
//

import UIKit
import KeychainSwift

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

class NotificationPageVC: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningText: UILabel!
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    private var tableData = [NotificationsSection]()

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
        tableView.allowsSelection = true
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        
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
        clearTable()
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.getUserNotifications(userId: userId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(let response):
                        self.handleSuccess(response: response)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
    func handleSuccess(response: Notifications) {
        for notification in response.notifications {
            
            var id = ""
            
            if notification.isFriendshipRequestNotification.boolValue {
                id = "Friendship Requests"
            } else {
                id = "Unknown"
            }
            
            if let sectionIndex = tableData.firstIndex(where: { $0.id == id }) {
                tableData[sectionIndex].notifications.append(
                    NotificationCellModel(
                        requestUniqueKey: notification.requestUniqueKey,
                        userId: notification.userId,
                        userWholeName: notification.userWholeName,
                        userImageURL: Constants.getImageURLPrefix + Constants.userImagePrefix + notification.userId,
                        isFriendshipRequestNotification: notification.isFriendshipRequestNotification.boolValue,
                        delegate: self
                    )
                )
                
                tableView.beginUpdates()
                tableView.reloadSections(IndexSet(integer: sectionIndex), with: .fade)
                tableView.endUpdates()
            
            } else {
                
                let section = NotificationsSection(
                    id: id,
                    header: NotificationHeaderModel(title: id),
                    notifications: [
                        NotificationCellModel(
                            requestUniqueKey: notification.requestUniqueKey,
                            userId: notification.userId,
                            userWholeName: notification.userWholeName,
                            userImageURL: Constants.getImageURLPrefix + Constants.userImagePrefix + notification.userId,
                            isFriendshipRequestNotification: notification.isFriendshipRequestNotification.boolValue,
                            delegate: self
                        )
                    ]
                )
                
                tableData.append(section)
                
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: tableData.count-1), with: .fade)
                tableView.endUpdates()
                
            }

        }
    }
    
    func removeFromTable(elem: NotificationCellModel){
        for section in 0...tableData.count-1 {
            if let row = tableData[section].notifications.firstIndex(where: { $0.requestUniqueKey == elem.requestUniqueKey }) {
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
            }
        }
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getNotifications()
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }

}

extension NotificationPageVC: NotificationCellDelegate {
    
    func friendshipAccepted(_ notification: NotificationCell) {
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.acceptFriendshipRequest(userId: userId, fromUserId: notification.model.userId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.removeFromTable(elem: notification.model)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
    func friendshipRejected(_ notification: NotificationCell) {
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.rejectFriendshipRequest(userId: userId, requestUniqueKey: notification.model.requestUniqueKey) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.removeFromTable(elem: notification.model)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
}


extension NotificationPageVC: UITableViewDelegate, UITableViewDataSource {
    
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
}

