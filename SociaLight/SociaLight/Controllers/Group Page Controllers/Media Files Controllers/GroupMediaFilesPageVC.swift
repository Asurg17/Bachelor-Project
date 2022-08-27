//
//  GroupMediaFilesPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.08.22.
//

import UIKit
import SDWebImage

class GroupMediaFilesPageVC: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var warningLabel: UILabel!
    
    private let service = Service()
    
    var collectionData = [MediaFileCellModel]()
    
    private let refreshControl = UIRefreshControl()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group Media Files"
        
        checkGroup(group: group)
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getGroupMediaFiles()
    }
    
    func setupViews() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.showsVerticalScrollIndicator = false
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        
        collectionView.register(
            UINib(
                nibName: "MediaFileCell",
                bundle: nil
            ),
            forCellWithReuseIdentifier: "MediaFileCell"
        )
    }
    
    func getGroupMediaFiles() {
        let parameters = [
            "userId":  getUserId(),
            "groupId": group!.groupId
        ]
        
        service.getGroupMediaFiles(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.handleSuccess(mediaFiles: response.mediaFiles)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(mediaFiles: [MediaFile]) {
        var files = [MediaFileCellModel]()
        for mediaFile in mediaFiles {
            let imageKey = "in_group_image_" + mediaFile.messageId.replacingOccurrences(of: " ", with: "-")
            files.append(
                MediaFileCellModel(
                    imageKey: imageKey,
                    delegate: self
                )
            )
        }
        
        collectionData = files
        collectionView.reloadData()
    }
    
    func showWarningMessage() {
        warningLabel.isHidden = false
    }
    
    func hideWarningMessage() {
        warningLabel.isHidden = true
    }
    
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getGroupMediaFiles()
        self.refreshControl.endRefreshing()
    }
}

extension GroupMediaFilesPageVC: MediaFileCellDelegate {
    
    func cellDidClick(_ media: MediaFileCell) {
        if let imageURL = URL(string: Constants.getImageURLPrefix + media.model.imageKey) {
            navigateToImagePage(url: imageURL)
        }
    }
    
}

extension GroupMediaFilesPageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionData.count == 0) { showWarningMessage() } else { hideWarningMessage() }
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaFileCell", for: indexPath)
        if let mediaFileCell = cell as? MediaFileCell {
            mediaFileCell.configure(with: collectionData[indexPath.row])
        }
        cell.layoutIfNeeded()
        return cell
    }
    
}

extension GroupMediaFilesPageVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: 0,
            left: Constants.mediaFileCellOffset,
            bottom: 0,
            right: Constants.mediaFileCellOffset
        )
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let cellWidth = (collectionView.frame.width - (Constants.mediaFileCellOffset * (Constants.itemCount + 1))) / Constants.itemCount
        let cellHeight = cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return Constants.mediaFileCellOffset
    }
    
}
