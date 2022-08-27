//
//  EventsPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventsSection {
    
    var id: String
    var header: EventHeaderModel?
    var events = [EventCellModel]()
    
    var numberOfRows: Int {
        return events.count
    }
      
    init(id: String, header: EventHeaderModel?, events: [EventCellModel]) {
        self.id = id
        self.header = header
        self.events = events
    }
    
}

class EventsPageVC: UIViewController {
    
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningText: UILabel!
    
    private let service = Service()
    private var tableData = [EventsSection]()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        tableView.allowsSelection = true
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.tableRowHeight + Constants.tableViewOffset, bottom: 0, right: Constants.tableViewOffset)
        
        tableView.register(
            UINib(nibName: "EventCell", bundle: nil),
            forCellReuseIdentifier: "EventCell"
        )
        
        tableView.register(
            UINib(nibName: "EventHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "EventHeader"
        )
    }
    
    func getEvents() {
        
    }
    
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getEvents()
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

extension EventsPageVC: EventCellDelegate {
    
    func navigateToGroupPage(_ event: EventCell) {
        navigateToGroupMemberProfilePage(memberId: event.model.fromUserId)
    }
    
    func navigateToUserPage(_ event: EventCell) {
        navigateToGroupPage(
            group: Group(
                groupId: event.model.groupId,
                groupImage: event.model.image,
                membersCurrentNumber: Int(event.model.membersCount) ?? 0,
                membersMaxNumber: Int(event.model.groupCapacity) ?? 0,
                groupName: event.model.groupTitle,
                groupDescription: event.model.groupDescription,
                isPrivate: false,
                userRole: event.model.userRole
            ),
            isUserGroupMember: true //tu datova arc wamova eventi
        )
    }
    
}

extension EventsPageVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableData.isEmpty { warningText.isHidden = false } else { warningText.isHidden = true }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].numberOfRows
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerModel = tableData[section].header else { return nil}
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EventHeader")
        
        if let eventHeader = header as? EventHeader {
            eventHeader.configure(with: headerModel)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EventCell",
            for: indexPath
        )
        
        if let eventCell = cell as? EventCell {
            eventCell.configure(with: tableData[indexPath.section].events[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
}
