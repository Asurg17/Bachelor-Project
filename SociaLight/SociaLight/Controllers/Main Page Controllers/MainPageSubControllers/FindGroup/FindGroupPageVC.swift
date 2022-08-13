//
//  FindNewGroupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 12.06.22.
//

import UIKit
import KeychainSwift

class FindGroupPageVC: UIViewController, GroupCellDelegate {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var warningLabel: UILabel!
    
    @IBOutlet var groupIdentifierTextField: RoundCornerTextField!
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
    var collectionData: [GroupCellModel] = []
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        configureCollectionView()
    }
    
    func setupViews() {
        groupIdentifierTextField.delegate = self
    }
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = flowLayout
        
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
    
    func searchNewGroups() {
        if let groupIdentifier = groupIdentifierTextField.text {
            if groupIdentifier != "" {
                if let userId = keychain.get(Constants.userIdKey) {
                    loader.startAnimating()
                    service.searchNewGroups(userId: userId, groupIdentifier: groupIdentifier) { [weak self] result in
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
                    delegate: self
                )
            )
        }
        collectionData = userGroups
        collectionView.reloadData()
    }
    
    func cellDidClick(_ group: GroupCell) {
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.addUserToGroup(userId: userId, groupId: group.model.groupId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.loader.stopAnimating()
                    switch result {
                    case .success(_):
                        self.navigateToGroupPage(
                            group: Group(
                                groupId: group.model.groupId,
                                groupImage: (group.groupImage.image ?? UIImage(named: "Groupicon"))!,
                                membersCurrentNumber: (Int(group.model.groupMembersNum) ?? 0) + 1,
                                membersMaxNumber: Int(group.model.groupCapacity) ?? 0,
                                groupName: group.model.groupTitle,
                                groupDescription: group.model.groupDescription,
                                isPrivate: false
                            )
                        )
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        searchNewGroups()
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension FindGroupPageVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchNewGroups()
        textField.resignFirstResponder()
        return true
    }
}

extension FindGroupPageVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
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

extension FindGroupPageVC: UICollectionViewDelegateFlowLayout {
    
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
        let spareWidth = collectionView.frame.width - (2 * Constants.spacing) - ((Constants.itemCountInLine - 1) * Constants.spacing) - Constants.additionalSpacing
        let cellWidth = spareWidth / Constants.itemCountInLine
        let cellHeight = cellWidth * 1.40
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
        return Constants.lineSpacing
    }
    
}