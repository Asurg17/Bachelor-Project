//
//  FriendsPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 21.08.22.
//

import UIKit
import SDWebImage

class FriendsPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    private let refreshControl = UIRefreshControl()
    
    private var friends = [FriendCellModel]()
    private var tableData = [FriendCellModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Friends"
        setupViews()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        friendNameTextField.addTarget(self, action: #selector(FriendsPageVC.textFieldDidChange(_:)), for: .editingChanged)
        
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = tableView.frame.size.width / 10
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFiends()
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
                nibName: "FriendCell",
                bundle: nil
            ),
            forCellReuseIdentifier: "FriendCell"
        )
    }
    
    func getFiends() {
        let userId = getUserId()
        
        loader.startAnimating()
        service.getUserFriends(userId: userId) { [weak self] result in
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
    
    func handleSuccess(response: UserFriends) {
        var userFriends = [FriendCellModel]()
        for friend in response.friends {
            userFriends.append(
                FriendCellModel(
                    friendId: friend.friendId,
                    friendFristName: friend.friendFirstName,
                    friendLastName: friend.friendLastName,
                    friendImageURL: Constants.getImageURLPrefix + Constants.userImagePrefix + friend.friendId,
                    friendPhone: friend.friendPhone,
                    isSelected: false,
                    isFriendsPage: true,
                    delegate: self
                )
            )
        }
        friends = userFriends
        tableData = userFriends
        tableView.reloadData()
    }
    
    func filterFriends(filterString: String) {
        loader.startAnimating()
        var filteredFriends: [FriendCellModel] = []
        if filterString != "" {
            for friend in friends {
                if(friend.friendFristName.lowercased().contains(filterString.lowercased()) ||
                   friend.friendLastName.lowercased().contains(filterString.lowercased())) {
                    filteredFriends.append(friend)
                }
            }
        } else {
            filteredFriends = friends
        }
        tableData = filteredFriends
        tableView.reloadData()
        loader.stopAnimating()
    }
    
    func delete(at indexPath: IndexPath) {
        let userId = getUserId()
        
        let parameters = [
            "userId": userId,
            "friendId": tableData[indexPath.row].friendId
        ]
        
        service.unfriend(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    if let offset = self.friends.firstIndex(where: { $0.friendId ==  self.tableData[indexPath.row].friendId }) {
                        self.friends.remove(at: offset)
                    
                        self.tableData.remove(at: indexPath.row)
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                    }
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    func clear() {
        friendNameTextField.text = ""
        friendNameTextField.resignFirstResponder()
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        clear()
        getFiends()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filterFriends(filterString: textField.text ?? "")
    }
    
}

extension FriendsPageVC: FriendCellDelegate {
    
    func cellDidClick(_ friend: FriendCell) {
        if friendNameTextField.isFirstResponder { friendNameTextField.resignFirstResponder() }
        navigateToUserProfilePage(memberId: friend.model.friendId)
    }
    
}

extension FriendsPageVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension FriendsPageVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableData.count == 0) { showWarningMessage() } else { hideWarningMessage() }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FriendCell",
            for: indexPath
        )
        
        if let friendCell = cell as? FriendCell {
            friendCell.configure(with: tableData[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actions = [
            UIContextualAction(style: .destructive, title: "Unfriend", handler: { _,_,_ in
                self.delete(at: indexPath)
            })
        ]
        let configuration = UISwipeActionsConfiguration(actions: actions)
        return configuration
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
