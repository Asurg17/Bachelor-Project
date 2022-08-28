//
//  GroupMembersPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.08.22.
//

import UIKit
import SDWebImage

class GroupMembersPageVC: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var memberNameTextField: UITextField!
    @IBOutlet var addNewMemberBarButton: UIBarButtonItem!
    
    private let service = Service()
    
    private var members = [GroupMemberCellModel]()
    private var tableData = [GroupMemberCellModel]()
    
    private let refreshControl = UIRefreshControl()
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group Members"
        
        setupViews()
        checkGroup(group: group)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getGroupMembers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        memberNameTextField.addTarget(self, action: #selector(GroupMembersPageVC.textFieldDidChange(_:)), for: .editingChanged)
    }

    func setupViews() {
        configureTableView()
    }
    
    func checkGroupMembersNum () {
        group!.membersCurrentNumber = tableData.count
        addNewMemberBarButton.isEnabled = !(group!.membersMaxNumber == group!.membersCurrentNumber)
    }
    
    func configureTableView() {
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = tableView.frame.size.width / 10
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = true
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.tableRowHeight + Constants.tableViewOffset, bottom: 0, right: Constants.tableViewOffset)
        
        tableView.register(
            UINib(
                nibName: "GroupMemberCell",
                bundle: nil
            ),
            forCellReuseIdentifier: "GroupMemberCell"
        )
    }
    
    func getGroupMembers() {
        let userId = getUserId()
        
        loader.startAnimating()
        service.getGroupMembers(userId: userId, groupId: group!.groupId) { [weak self] result in
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
    
    func handleSuccess(response: GroupMembers) {
        var groupMembers = [GroupMemberCellModel]()
        for member in response.members {
            groupMembers.append(
                GroupMemberCellModel(
                    memberId: member.memberId,
                    memberFristName: member.memberFirstName,
                    memberLastName: member.memberLastName,
                    memberImageURL: Constants.getImageURLPrefix + Constants.userImagePrefix + member.memberId,
                    memberPhone: member.memberPhone,
                    isFriendRequestAlreadySent: member.isFriendRequestAlreadySent,
                    areAlreadyFriends: member.areAlreadyFriends,
                    delegate: self)
            )
        }
        members = groupMembers
        tableData = groupMembers
        //checkGroupMembersNum()
        tableView.reloadData()
    }
    
    func filter(filterString: String) {
        loader.startAnimating()
        var filteredMembers: [GroupMemberCellModel] = []
        if filterString != "" {
            for member in members {
                if(member.memberFristName.lowercased().contains(filterString.lowercased()) ||
                   member.memberLastName.lowercased().contains(filterString.lowercased())) {
                    filteredMembers.append(member)
                }
            }
        } else {
            filteredMembers = members
        }
        tableData = filteredMembers
        tableView.reloadData()
        loader.stopAnimating()
    }
    
    func clearNameTextField() {
        memberNameTextField.text = ""
        memberNameTextField.resignFirstResponder()
    }
    
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addNewMembers() {
        navigateToAddGroupMembersPage(group: group!)
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        clearNameTextField()
        getGroupMembers()
        self.refreshControl.endRefreshing()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filter(filterString: textField.text ?? "")
    }
    
}

extension GroupMembersPageVC: GroupMemberCellDelegate {
 
    func sendFriendshipRequest(_ member: GroupMemberCell) {
        let userId = getUserId()
        
        service.sendFriendshipRequest(fromUserId: userId, toUserId: member.model.memberId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.stopAnimating()
                switch result {
                case .success(_):
                    ()
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func userIsClicked(_ member: GroupMemberCell) {
        if member.model.memberId != getUserId() {
            navigateToUserProfilePage(memberId: member.model.memberId)
        }
    }
    
}


extension GroupMembersPageVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "GroupMemberCell",
            for: indexPath
        )
        
        if let groupMemberCell = cell as? GroupMemberCell {
            groupMemberCell.configure(with: tableData[indexPath.row])
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
