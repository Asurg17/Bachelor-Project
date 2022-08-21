//
//  AddGroupMembersPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.08.22.
//

import UIKit
import SDWebImage

class AddGroupMembersPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var collectionViewWarningLabel: UILabel!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private let service = Service()
    
    private let refreshControl = UIRefreshControl()
    
    private var friends = [FriendCellModel]()
    private var tableData = [FriendCellModel]()
    private var collectionData = [SelectedFriendCellModel]()
    
    var group: Group?
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Group Members"
        
        setupViews()
        checkGroup(group: group)
        getFiends()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        friendNameTextField.addTarget(self, action: #selector(AddGroupMembersPageVC.textFieldDidChange(_:)), for: .editingChanged)
        
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = tableView.frame.size.width / 10
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
    
    func setupViews() {
        configureTableView()
        configureCollectionView()
    }
    
    func configureTableView() {
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
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.keyboardDismissMode = .interactive
        collectionView.collectionViewLayout = flowLayout
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(
            UINib(
                nibName: "SelectedFriendCell",
                bundle: nil
            ),
            forCellWithReuseIdentifier: "SelectedFriendCell"
        )
    }
    
    func getFiends() {
        let userId = getUserId()
            
        loader.startAnimating()
        service.getUserFriends(userId: userId, groupId: group!.groupId) { [weak self] result in
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
                    isFriendsPage: false,
                    delegate: self
                )
            )
        }
        friends = userFriends
        tableData = userFriends
        tableView.reloadData()
    }
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    func showTableWarningMessage() {
        collectionViewWarningLabel.isHidden = false
    }
    
    func hideTableWarningMessage() {
        collectionViewWarningLabel.isHidden = true
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
    
    func addGroupMembers() {
        let userId = getUserId()
        
        let members = getMembers()
        if members.count > 0 {
            service.addGroupMembers(userId: userId, groupId: group!.groupId, addSelfToGroup: "N", members: members) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.back()
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        }
    }
    
    func getMembers() -> Array<String> {
        var members = [String]()
        for member in collectionData {
            members.append(member.friendId)
        }
        return members
    }
    
    func clear() {
        friendNameTextField.text = ""
        friendNameTextField.resignFirstResponder()
        
        collectionData = [SelectedFriendCellModel]()
        collectionView.reloadData()
    }
    
    @IBAction func add() {
        addGroupMembers()
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        clear()
        getFiends()
        self.refreshControl.endRefreshing()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filterFriends(filterString: textField.text ?? "")
    }
    
}

extension AddGroupMembersPageVC: FriendCellDelegate {
    
    func cellDidClick(_ friend: FriendCell) {
        if(friend.model.isSelected) {
            //if collectionData.count < (group!.membersMaxNumber - group!.membersCurrentNumber) {
                collectionData.append(
                    SelectedFriendCellModel(
                        friendId: friend.model.friendId,
                        friendFristName: friend.model.friendFristName,
                        friendImage: friend.model.friendImage
                    )
                )
//            } else {
//                friend.toggleSelection()
//                showWarningAlert(
//                    warningText: Constants.maximalGroupMembersNumberReachedWarningText
//                )
//            }
        } else {
            if let offset = collectionData.firstIndex(where: {$0.friendId == friend.model.friendId}) {
                collectionData.remove(at: offset)
            }
        }
        collectionView.reloadData()
    }
    
}

extension AddGroupMembersPageVC: UITableViewDelegate, UITableViewDataSource {
    
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

extension AddGroupMembersPageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionData.count == 0) { showTableWarningMessage() } else { hideTableWarningMessage() }
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedFriendCell", for: indexPath)
        if let selectedFriendCell = cell as? SelectedFriendCell {
            selectedFriendCell.configure(with: collectionData[indexPath.row])
        }
        cell.layoutIfNeeded()
        return cell
    }
    
}

extension AddGroupMembersPageVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: 0,
            left: Constants.spacing,
            bottom: 0,
            right: Constants.spacing
        )
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        var spareWidth = collectionView.frame.width - ((Double(Constants.itemCount) + 1.0) * Constants.spacing)
        spareWidth = spareWidth * 0.9
        let cellWidth  = spareWidth / Double(Constants.itemCount)
        let cellHeight = collectionView.frame.height
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return Constants.spacing
    }
    
}

