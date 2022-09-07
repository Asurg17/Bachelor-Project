//
//  FriendsSearchPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 03.09.22.
//

import UIKit
import SDWebImage
import JGProgressHUD

class FriendsSearchPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var warningLabel: UILabel!
    
    private let service = UserService()
    private let notificationService = NotificationService()
    private let loader = JGProgressHUD()
    private let refreshControl = UIRefreshControl()
    private var tableData = [SearchFriendCellModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search Friends"
        setupViews()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = tableView.frame.size.width / 10
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    func setupViews() {
        friendNameTextField.delegate = self
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = true
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.tableRowHeight + Constants.tableViewOffset, bottom: 0, right: Constants.tableViewOffset)
        
        tableView.register(
            UINib(
                nibName: "SearchFriendCell",
                bundle: nil
            ),
            forCellReuseIdentifier: "SearchFriendCell"
        )
    }
    
    func searchFriends() {
        if let text = friendNameTextField.text {
            if !text.replacingOccurrences(of: " ", with: "").isEmpty {
                let words = text.components(separatedBy: " ")
    
                let firstName = words[0]
                let lastName = words[1..<words.count].joined(separator: " ")
                
                print(firstName)
                print(lastName)
                print(getUserId())
                
                showLoader()
                service.searchNewFriends(userId: getUserId(), firstName: firstName, lastName: lastName) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.loader.dismiss(animated: true)
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
        }
    }
    
    func handleSuccess(response: UserFriends) {
        var potentialFriends = [SearchFriendCellModel]()
        for potentialFriend in response.friends {
            potentialFriends.append(
                SearchFriendCellModel(
                    userId: potentialFriend.friendId,
                    userFristName: potentialFriend.friendFirstName,
                    userLastName: potentialFriend.friendLastName,
                    delegate: self
                )
            )
        }
        tableData = potentialFriends
        tableView.reloadData()
    }
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    func showLoader() {
        loader.textLabel.text = "Loading..."
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        searchFriends()
    }
    
}

extension FriendsSearchPageVC: SearchFriendCellDelegate {
    func sendFriendshipRequest(_ user: SearchFriendCell) {
        let userId = getUserId()
        
        service.sendFriendshipRequestToUser(fromUserId: userId, toUserId: user.model.userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    user.setIcon()
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func userIsClicked(_ user: SearchFriendCell) {
        navigateToUserProfilePage(userId: user.model.userId)
    }
}

extension FriendsSearchPageVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchFriends()
        return true
    }
}

extension FriendsSearchPageVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableData.count == 0) { showWarningMessage() } else { hideWarningMessage() }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SearchFriendCell",
            for: indexPath
        )
        
        if let searchFriendCell = cell as? SearchFriendCell {
            searchFriendCell.configure(with: tableData[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
}
