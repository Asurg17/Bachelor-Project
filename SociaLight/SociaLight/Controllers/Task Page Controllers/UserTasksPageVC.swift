//
//  UserTasksPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 03.09.22.
//

import UIKit
import JGProgressHUD


class TasksSection {
    var id: String
    var header: TaskHeaderModel?
    var tasks = [TaskCellModel]()
    
    var numberOfRows: Int {
        return tasks.count
    }
      
    init(id: String, header: TaskHeaderModel?, tasks: [TaskCellModel]) {
        self.id = id
        self.header = header
        self.tasks = tasks
    }
}

class UserTasksPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningLabel: UILabel!

    private let groupService = GroupService()
    private let taskService = TaskService()
    private var loader = JGProgressHUD()
    private var members = [GroupMember]()
    private var hasLoadedGroupMembers = false
    private let refreshControl = UIRefreshControl()
    private var tableData = [TasksSection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserTasks()
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
    
    func clearTable() {
        tableData = []
        tableView.reloadData()
    }
    
    func getUserTasks() {
        let parameters = [
            "userId": getUserId(),
            "currentDate": formatEventDate(date: Date())
        ]
        
        showLoader(text: "Loading Data...")
        taskService.getUserTasks(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loader.dismiss(animated: true)
                switch result {
                case .success(let response):
                    self.clearTable()
                    self.handleSuccess(tasks: response.tasks)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(tasks: [Task]) {
        for task in tasks {
            let id = task.date
            
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
                isUserTasksPage: true,
                delegate: self
            )
            
            if let sectionIndex = tableData.firstIndex(where: { $0.id == id }) {
                tableData[sectionIndex].tasks.append(taskCellModel)
            } else {
                let section = TasksSection(
                    id: id,
                    header: TaskHeaderModel(title: id),
                    tasks: [taskCellModel]
                )
                tableData.append(section)
            }
        }
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
        self.navigationController?.popToViewController(ofClass: GroupInfoPageVC.self, animated: true)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getUserTasks()
    }
    
}

extension UserTasksPageVC: TaskCellProtocol {
    func navigate(eventKey: String) {
        navigateToEventPage(eventKey: eventKey)
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

extension UserTasksPageVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableData.isEmpty { warningLabel.isHidden = false } else { warningLabel.isHidden = true }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].numberOfRows
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let taskHeaderModel = tableData[section].header else { return nil}
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TaskHeader")
        
        if let taskHeader = header as? TaskHeader {
            taskHeader.configure(with: taskHeaderModel)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TaskCell",
            for: indexPath
        )
        
        if let taskCell = cell as? TaskCell {
            taskCell.configure(with: tableData[indexPath.section].tasks[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
