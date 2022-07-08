//
//  NewGroupSecondVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.06.22.
//

import UIKit
import KeychainSwift

class NewGroupSecondVC: UIViewController, FriendCellDelegate {
    
    @IBOutlet var tableViewOuterView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var friendNameTextField: UITextField!
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var tableWarningLabel: UILabel!
    
    @IBOutlet var loader: UIActivityIndicatorView!
    
    private var friends = [FriendCellModel]()
    private var tableData = [FriendCellModel]()
    private var collectionData = [SelectedFriendCellModel]()
    
    var image: UIImage?
    var membersCount: Int?
    var groupName: String?
    var groupDescription: String?
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupViews()
        getFiends()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        friendNameTextField.addTarget(self, action: #selector(NewGroupSecondVC.textFieldDidChange(_:)), for: .editingChanged)
        
        tableViewOuterView.clipsToBounds = true
        tableViewOuterView.layer.cornerRadius = tableViewOuterView.frame.size.width / 10
        tableViewOuterView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true
        
        friendNameTextField.clearButtonMode = .whileEditing
        
        if let button = friendNameTextField.value(forKey: "clearButton") as? UIButton {
            button.tintColor = .black
            button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        }
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
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.getUserFriends(userId: userId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(let response):
                        self.handleSuccess(response: response)
                    case .failure(let error):
                        self.handleError(error: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.getUserFriendsErrorText)
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
        tableWarningLabel.isHidden = false
    }
    
    func hideTableWarningMessage() {
        tableWarningLabel.isHidden = true
    }
    
    func cellDidClick(_ friend: FriendCell) {
        if(friend.model.isSelected) {
            if collectionData.count < (membersCount ?? 0) - 1 {
                collectionData.append(
                    SelectedFriendCellModel(
                        friendId: friend.model.friendId,
                        friendFristName: friend.model.friendFristName,
                        friendImage: friend.model.friendImage
                    )
                )
            } else {
                friend.toggleSelection()
                showWarningAlert(
                    warningText: Constants.maximalGroupMembersNumberReachedWarningText
                )
            }
        } else {
            if let offset = collectionData.firstIndex(where: {$0.friendId == friend.model.friendId}) {
                collectionData.remove(at: offset)
            }
        }
        collectionView.reloadData()
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
    
    func createNewGroup() {
        if let userId = keychain.get(Constants.userIdKey) {
            print("create group" + userId)
        } else {
            showWarningAlert(warningText: Constants.createGroupErrorText)
        }
    }
    
    @IBAction func createGroup() {
        createNewGroup()
    }
    
    @IBAction func back() {
        dismiss(animated: true, completion: nil)
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filterFriends(filterString: textField.text ?? "")
    }
    
}

extension NewGroupSecondVC: UITableViewDelegate, UITableViewDataSource {
    
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

extension NewGroupSecondVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
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

extension NewGroupSecondVC: UICollectionViewDelegateFlowLayout {
    
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
        let spareWidth = collectionView.frame.width - ((Double(Constants.itemCount) + 1.0) * Constants.spacing)
        let cellWidth = spareWidth / Double(Constants.itemCount)
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

