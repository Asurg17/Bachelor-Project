//
//  MainPageController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.05.22.
//

import UIKit
import KeychainSwift

class MainPageVC: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var filterTextField: RoundCornerTextField!
    
    @IBOutlet var warningLabel: UILabel!
    
    private let service = Service()
    
    var collectionData = [GroupCellModel]()
    var groups = [GroupCellModel]()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        configureCollectionView()
        getUserGroups()
    }
    
    func setupViews() {
        filterTextField.addTarget(self, action: #selector(MainPageVC.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(
            UINib(
                nibName: "GroupCell",
                bundle: nil
            ),
            forCellWithReuseIdentifier: "GroupCell"
        )
        
        collectionView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap(guesture:))
            )
        )
    }
    
    func getUserGroups() {
        let keychain = KeychainSwift()
        if let userId = keychain.get(Constants.userIdKey) {
            loader.startAnimating()
            service.getUserGroups(userId: userId) { [weak self] result in
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
            showWarningAlert(warningText: Constants.getUserGroupsErrorText)
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
                    groupImageURL: Constants.getImageURLPrefix + Constants.groupImagePrefix + group.groupId
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
    
    func navigateToGroupPage(grouId: String) {
        print("Navigate To " + grouId)
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filterGroups(filterString: textField.text ?? "")
    }
    
    @objc func handleTap(guesture: UITapGestureRecognizer) {
        if(guesture.state == UIGestureRecognizer.State.ended) {
            let location = guesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: location) {
                if let _ = collectionView.cellForItem(at: indexPath) {
                    print(indexPath.row)
                    if collectionData.indices.contains(indexPath.row) {
                        navigateToGroupPage(grouId: collectionData[indexPath.row].groupId)
                    }
                }
            }
        }
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
