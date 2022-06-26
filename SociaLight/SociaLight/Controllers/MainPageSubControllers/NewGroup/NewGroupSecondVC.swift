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
    
    let tableRowHeight = 80.0
    let tableViewOffset = 32.0
    
    private var tableData = [FriendCellModel]()
    private var collectionData = [UserFriend]()
    
    var image: String?
    var membersCount: Int?
    var groupName: String?
    var groupDescription: String?
    
    private let service = Service()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
//        flowLayout.minimumInteritemSpacing = 0;
//        flowLayout.minimumLineSpacing = 0;
        return flowLayout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableData = [FriendCellModel(friendId: "1", friendFristName: "Anna", friendLastName: "Mitchelson", friendPhone: "576493709", isSelected: false, delegate: self),FriendCellModel(friendId: "2", friendFristName: "Mike", friendLastName: "Justundart", friendPhone: "689342375", isSelected: false, delegate: self),FriendCellModel(friendId: "3", friendFristName: "Ellen", friendLastName: "Levski", friendPhone: "78906543376", isSelected: false, delegate: self),FriendCellModel(friendId: "4", friendFristName: "Goldar", friendLastName: "Smith", friendPhone: "82375757", isSelected: false, delegate: self),FriendCellModel(friendId: "6", friendFristName: "Lika", friendLastName: "Khujadze", friendPhone: "578906543", isSelected: false, delegate: self),FriendCellModel(friendId: "5", friendFristName: "Mariam", friendLastName: "Nafetvaridze", friendPhone: "575678943", isSelected: false, delegate: self),FriendCellModel(friendId: "7", friendFristName: "Eka", friendLastName: "Jalaghonia", friendPhone: "543679022", isSelected: false, delegate: self),FriendCellModel(friendId: "9", friendFristName: "Maka", friendLastName: "Petri", friendPhone: "555768900", isSelected: false, delegate: self),FriendCellModel(friendId: "8", friendFristName: "Lisa", friendLastName: "Axlvediani", friendPhone: "571345890", isSelected: false, delegate: self)]
        
        setupViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tableRowHeight + tableViewOffset, bottom: 0, right: tableViewOffset)
        
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
        
//        collectionView.addGestureRecognizer(
//            UITapGestureRecognizer(
//                target: self,
//                action: #selector(handleTap(guesture:))
//            )
//        )
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
           collectionData.append(
            UserFriend(
                friendId: friend.model.friendId,
                friendFirstName: friend.model.friendFristName,
                friendLastName: friend.model.friendLastName,
                friendPhone: friend.model.friendPhone
            ))
        } else {
            if let offset = collectionData.firstIndex(where: {$0.friendId == friend.model.friendId}) {
                collectionData.remove(at: offset)
            }
        }
        collectionView.reloadData()
    }
    
    
    @IBAction func createGroup() {
        print("Create Group")
    }
    
    @IBAction func back() {
        dismiss(animated: true, completion: nil)
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
        return tableRowHeight
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
        let spareWidth = collectionView.frame.width - ((4 - 1) * 10) - 10 - 50
        let cellWidth = spareWidth / 4
//        print(cellWidth)
//        print(collectionView.frame.height)
        let cellHeight = collectionView.frame.height
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 10
    }
    
}

