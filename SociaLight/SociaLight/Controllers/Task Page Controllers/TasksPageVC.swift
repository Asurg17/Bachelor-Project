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

    private let groupService = GroupService()
    private let taskService = TaskService()
    private var loader = JGProgressHUD()
    private var members = [GroupMember]()
    private var hasLoadedGroupMembers = false
    private let refreshControl = UIRefreshControl()
    private var tableData = [TaskCellModel]()
    
    var eventKey: String!
    var creatorId: String!
    var groupId: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getGroupMembers()
    }
    
    func setupViews() {
        if creatorId == getUserId() {
            let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(buttonClicked))
            self.navigationItem.rightBarButtonItem  = addButton
        }
    }
    
    func setupTableView() {
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 20
        tableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = false
        
        tableView.layoutMargins.left = 0.1
        tableView.layoutMargins.right = 0.1
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.tableRowHeight + Constants.tableViewOffset, bottom: 0, right: Constants.tableViewOffset)
        
        tableView.register(
            UINib(nibName: "TaskCell", bundle: nil),
            forCellReuseIdentifier: "TaskCell"
        )
        
        tableView.register(
            UINib(nibName: "TaskHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "TaskHeader"
        )
    }
    
    func getGroupMembers() {
        let userId = getUserId()
        let groupId = groupId!
        
        showLoader(text: "Loading Data...")
        groupService.getGroupMembers(userId: userId, groupId: groupId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.handleGroupMembers(members: response.members)
                    self.getEventTasks()
                case .failure(let error):
                    self.loader.dismiss(animated: true)
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleGroupMembers(members: [GroupMember]) {
        self.members = members
        self.hasLoadedGroupMembers = true
    }
    
    func getEventTasks() {
        let parameters = [
            "userId": getUserId(),
            "eventKey": eventKey!
        ]
        
        taskService.getEventTasks(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loader.dismiss(animated: true)
                switch result {
                case .success(let response):
                    self.handleSuccess(tasks: response.tasks)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(tasks: [Task]) {
        var eventTasks = [TaskCellModel]()
        for task in tasks {
            let taskCellModel = TaskCellModel(
                assigneeId: task.assigneeId,
                assigneeName: task.assigneeName,
                eventKey: task.eventKey,
                taskTitle: task.taskTitle,
                date: task.date,
                time: task.time,
                taskId: task.taskId,
                taskStatus: task.taskStatus,
                currentUserId: getUserId(),
                isUserTasksPage: false,
                delegate: self
            )
            eventTasks.append(taskCellModel)
        }
        tableData = eventTasks
        tableView.reloadData()
    }
    
    func showLoader(text: String) {
        loader = JGProgressHUD()
        loader.textLabel.text = text
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    func dismissLoader() {
        UIView.animate(withDuration: 0.2, animations: {
            self.loader.textLabel.text = "Success"
            self.loader.detailTextLabel.text = nil
            self.loader.indicatorView = JGProgressHUDSuccessIndicatorView()
        })
                       
        loader.dismiss(animated: true)
    }
    
    @IBAction func back() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getEventTasks()
    }

    @objc func buttonClicked() {
        if hasLoadedGroupMembers {
            navigateToNewTaskPopupVC(members: members, eventKey: eventKey, vc: self)
        }
    }
}

extension TasksPageVC: TaskCellProtocol {
    func navigate(eventKey: String) {
        ()
    }
    
    func doneTask(_ task: TaskCell) {
        let parameters = [
            "userId": getUserId(),
            "taskId": task.model.taskId
        ]
        
        showLoader(text: "Processing...")
        taskService.doneTask(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.dismissLoader()
                switch result {
                case .success(_):
                    task.model.taskStatus = "D"
                    task.checkIfTaskIsDone()
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
}

extension TasksPageVC: UpdateTasksProtocol {
    func update() {
        getEventTasks()
    }
}

extension TasksPageVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableData.isEmpty { warningLabel.isHidden = false } else { warningLabel.isHidden = true }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TaskCell",
            for: indexPath
        )
        
        if let taskCell = cell as? TaskCell {
            taskCell.configure(with: tableData[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

