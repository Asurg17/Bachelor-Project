//
//  TasksPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.09.22.
//

import UIKit
import JGProgressHUD

class TasksPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningLabel: UILabel!

    private let loader = JGProgressHUD()
    private let service = Service()
    private var members = [GroupMember]()
    private var hasLoadedGroupMembers = false
    
    var event: NewEvent!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getGroupMembers()
    }
    
    func getGroupMembers() {
        let userId = getUserId()
        let groupId = getGroupId()
        
        showLoader()
        service.getGroupMembers(userId: userId, groupId: groupId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.dismiss(animated: true)
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
        members = response.members
        hasLoadedGroupMembers = true
    }
    
    func showLoader() {
        loader.textLabel.text = "Loading Data..."
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    @IBAction func buttonClicked() {
        if hasLoadedGroupMembers {
            navigateToNewTaskPopupVC(members: members)
        }
    }
    
    @IBAction func back() {
        self.navigationController?.popToViewController(ofClass: GroupInfoPageVC.self, animated: true)
    }
    
}
