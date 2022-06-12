//
//  FindNewGroupViewController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 12.06.22.
//

import UIKit
import KeychainSwift

class FindNewGroupViewController: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var groupNameTextField: RoundCornerTextField!
    
    private let service = Service()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
    var collectionData: [UserGroup] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
    }
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = flowLayout
        
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
    
    func searchUserGroups(groupName: String) {
        let keychain = KeychainSwift()
        if let userId = keychain.get("userId") {
            loader.startAnimating()
            service.searchUserGroups(userId: userId, groupName: groupName) { [weak self] result in
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
            showWarningAlert(warningText: "Could not get user Info!")
        }
    }
    
    func handleSuccess(response: UserGroups) {
        collectionData = response.groups
        collectionView.reloadData()
    }
    
    func handleError(error: String?) {
        showWarningAlert(warningText: error ?? "Unspecified Error!")
    }
    
    func navigateToGroupPage(grouId: String) {
        print("Navigate To " + grouId)
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
    
    
    @IBAction func searchGroups() {
        if let groupName = groupNameTextField.text {
            if groupName != "" {
                searchUserGroups(groupName: groupName)
            }
        }
    }
}

extension FindNewGroupViewController: UICollectionViewDelegate {
    
}

extension FindNewGroupViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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

extension FindNewGroupViewController: UICollectionViewDelegateFlowLayout {
    
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
