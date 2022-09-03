//
//  EventsPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit
import JGProgressHUD

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
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var warningText: UILabel!
    
    private let service = EventService()
    private var tableData = [EventsSection]()
    private let loader = JGProgressHUD()
    
    var groupId: String?
    
    private let refreshControl = UIRefreshControl()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getEvents()
    }
    
    func setupViews() {
        setupTableView()
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
            UINib(nibName: "EventCell", bundle: nil),
            forCellReuseIdentifier: "EventCell"
        )
        
        tableView.register(
            UINib(nibName: "EventHeader", bundle: nil),
            forHeaderFooterViewReuseIdentifier: "EventHeader"
        )
    }
    
    func clearTable() {
        tableData = []
        tableView.reloadData()
    }
    
    func getEvents() {
        let parameters = [
            "userId": getUserId(),
            "groupId": groupId ?? "",
            "currentDate": formatEventDate(date: Date())
        ]
        
        showLoader()
        service.getEvents(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loader.dismiss(animated: true)
                switch result {
                case .success(let response):
                    self.clearTable()
                    self.handleSuccess(events: response.events)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(events: [Event]) {
        for event in events {
         
            let id = event.date
            
            let eventCellModel = EventCellModel(
                eventUniqueKey: event.eventUniqueKey,
                creatorId: event.creatorId,
                toUserId: event.toUserId,
                groupId: event.groupId,
                eventHeader: event.eventHeader,
                eventTitle: event.eventTitle,
                eventDescription: event.eventDescription,
                place: event.place,
                eventType: event.eventType,
                date: event.date,
                time: event.time,
                delegate: self
            )
            
            if let sectionIndex = tableData.firstIndex(where: { $0.id == id }) {
                tableData[sectionIndex].events.append(eventCellModel)
            } else {
                let section = EventsSection(
                    id: id,
                    header: EventHeaderModel(title: id),
                    events: [eventCellModel]
                )
                tableData.append(section)
            }
        }
        tableView.reloadData()
    }
    
    func showLoader() {
        loader.textLabel.text = "Loading..."
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    @objc private func didPullToRefresh(_ sender: Any) {
        getEvents()
    }
}

extension EventsPageVC: EventCellDelegate {
    func navigate(eventKey: String) {
        navigateToEventPage(eventKey: eventKey)
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
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
