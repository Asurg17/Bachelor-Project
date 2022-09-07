//
//  MainPageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.05.22.
//

import UIKit

class MainPageVC: UIViewController, GroupCellDelegate {

    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var filterTextField: RoundCornerTextField!
    @IBOutlet var warningLabel: UILabel!
    
    private let userService = UserService()
    private let notificationService = NotificationService()
    private var isSocketClosed = false
    
    var collectionData = [GroupCellModel]()
    var groups = [GroupCellModel]()
    
    private let refreshControl = UIRefreshControl()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
// WebSocket
    
    private var webSocket: URLSessionWebSocketTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createWebSocket() // create web socket
        setupViews()
        hideKeyboardWhenTappedAround()
        configureCollectionView()
        checkForNewNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getUserGroups()
    }
    
    func setupViews() {
        filterTextField.addTarget(
            self,
            action: #selector(MainPageVC.textFieldDidChange(_:)), for: .editingChanged
        )
        
        filterTextField.delegate = self
    }
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.showsVerticalScrollIndicator = false
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        
        collectionView.register(
            UINib(
                nibName: "GroupCell",
                bundle: nil
            ),
            forCellWithReuseIdentifier: "GroupCell"
        )
    }
    
    func checkForNewNotifications() {
        var lastSeenNotificationUniqueKey = "-1"
        if let uniqeuKey = UserDefaults.standard.string(forKey: Constants.lastSeenNotificationKey) {
            lastSeenNotificationUniqueKey = uniqeuKey
        }
        
        let parameters = [
            "userId": getUserId(),
            "lastSeenNotificationUniqueKey": lastSeenNotificationUniqueKey
        ]
       
        notificationService.checkForNewNotifications(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let tabBarItem = self.tabBarController?.tabBar.items?[1],
                       let num = Int(response.newNotificationsNum) {
                        if num != 0 {
                            if num > 9 {
                                tabBarItem.badgeValue = "9+"
                            } else {
                                tabBarItem.badgeValue = response.newNotificationsNum
                            }
                        }
                    }
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func getUserGroups() {
        let userId = getUserId()
       
        loader.startAnimating()
        userService.getUserGroups(userId: userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                self.refreshControl.endRefreshing()
                switch result {
                case .success(let response):
                    self.handleSuccess(response: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(response: UserGroups) {
        var userGroups = [GroupCellModel]()
        for group in response.groups {
            userGroups.append(
                GroupCellModel(
                    groupId: group.groupId,
                    groupTitle: group.groupTitle,
                    groupDescription: group.groupDescription,
                    groupImageURL: Constants.getImageURLPrefix + Constants.groupImagePrefix + group.groupId,
                    groupCapacity: group.groupCapacity,
                    groupMembersNum: group.groupMembersNum,
                    userRole: group.userRole,
                    newMessagesCount: group.newMessagesCount,
                    delegate: self
                )
            )
        }
        groups = userGroups
        collectionData = userGroups
        collectionView.reloadData()
    }
    
    func filterGroups(filterString: String) {
        loader.startAnimating()
        var filteredGroups: [GroupCellModel] = []
        if filterString != "" {
            for group in groups {
                if(group.groupTitle.lowercased().contains(filterString.lowercased())) {
                    filteredGroups.append(group)
                }
            }
        } else {
            filteredGroups = groups
        }
        collectionData = filteredGroups
        collectionView.reloadData()
        loader.stopAnimating()
    }
    
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    func clearFilterText() {
        filterTextField.text = ""
        filterTextField.resignFirstResponder()
    }
    
    func cellDidClick(_ group: GroupCell) {
        filterTextField.text = ""
        navigateToGroupPage(
            groupId: group.model.groupId,
            isUserGroupMember: true
        )
    }
    
    func isNotificationsPageVisible() -> Bool {
        if let tc = self.tabBarController,
           let vcs = tc.viewControllers,
           let nc = vcs[1] as? UINavigationController,
           let vc = nc.viewControllers[0] as? NotificationsPageVC {
            let isNotificationsViewVisible = (vc.isViewLoaded && vc.view.window != nil)
            if isNotificationsViewVisible {
                vc.getNewNotifications()
            }
            return isNotificationsViewVisible
        }
        return false
    }
    
    func updateNotificationsBadge() {
        if !isNotificationsPageVisible() {
            if let tabBarItem = self.tabBarController?.tabBar.items?[1] {
                let currentBadgeStringValue = tabBarItem.badgeValue ?? "0"
                if currentBadgeStringValue != "9+" {
                    if let currentBadgeIntValue = Int(currentBadgeStringValue) {
                        if currentBadgeIntValue == 9 {
                            tabBarItem.badgeValue = "9+"
                        } else {
                            tabBarItem.badgeValue = String(currentBadgeIntValue + 1)
                        }
                    }
                }
            }
        }
    }
    
    func updateGroupBadge(groupId: String) {
        if let offset = groups.firstIndex(where: {$0.groupId == groupId}) {
            groups[offset].newMessagesCount = "1"
        }
        
        if let collectionDataOffset = collectionData.firstIndex(where: {$0.groupId == groupId}) {
            collectionData[collectionDataOffset].newMessagesCount = "1"
            collectionView.reloadItems(at: [IndexPath(row: collectionDataOffset, section: 0)])
        }
    }
    
    // WebSocket
    
    func createWebSocket() {
        let session = URLSession(
            configuration: .default ,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        
        if let url = URL(string: "ws://\(ServerStruct.serverHost):\(ServerStruct.serverPort)\(Constants.mainWsEndpoint)\(getUserId())") {
            webSocket = session.webSocketTask(with: url)
            webSocket?.resume()
        } // esle way
    }
    
    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func close() {
        webSocket?.cancel(with: .goingAway, reason: "Close The Connection".data(using: .utf8))
    }
    
    func send() {
    }
    
    func receive() {
        self.webSocket?.receive(completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    print("data")
                    DispatchQueue.main.sync {
                        self.updateNotificationsBadge()
                    }
                case .string(let string):
                    print("string")
                    DispatchQueue.main.sync {
                        self.updateGroupBadge(groupId: string)
                    }
                default:
                    break
                }
            case .failure(let error):
                
                print("Received error: \(error)")
            }
            
            self.receive()
        })
    }
    
    @IBAction func goToFindGroupVC() {
        if filterTextField.isFirstResponder { filterTextField.resignFirstResponder() }
        navigateToFindGroupPage()
    }
    
    @IBAction func goToNewGroupVC() {
        if filterTextField.isFirstResponder { filterTextField.resignFirstResponder() }
        navigateToNewGroupPage()
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        clearFilterText()
        getUserGroups()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filterGroups(filterString: textField.text ?? "")
    }
    
}

extension MainPageVC: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
        ping()
        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Disconnect from Server")
        isSocketClosed = true
    }
    
}

extension MainPageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionData.count == 0) { showWarningMessage() } else { hideWarningMessage() }
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath)
        if let groupCell = cell as? GroupCell {
            groupCell.configure(with: collectionData[indexPath.row])
        }
        cell.layoutIfNeeded()
        return cell
    }
}

extension MainPageVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: Constants.topBottomSpacing,
            left: Constants.spacing,
            bottom: Constants.topBottomSpacing,
            right: Constants.spacing
        )
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let spareWidth = collectionView.frame.width - ((Constants.itemCountInLine + 1) * Constants.spacing) - Constants.additionalSpacing
        let cellWidth = spareWidth / Constants.itemCountInLine
        let cellHeight = cellWidth * 1.55
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return Constants.spacing
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0.0
    }
    
}

extension MainPageVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
