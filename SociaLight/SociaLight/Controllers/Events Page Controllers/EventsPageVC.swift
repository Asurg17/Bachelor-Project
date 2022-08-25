//
//  EventsPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventsPageVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let one = "Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor         Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor         Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor         Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor         Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor         Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor"
    
    let two = "Hodor"
    
    let three = "Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor               Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor               Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor Hodor"
    
    private var tableData: [String] = []
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableData.append(one)
        tableData.append(two)
        tableData.append(three)
        
        setupTableView()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(
            UINib(nibName: "EventCell", bundle: nil),
            forCellReuseIdentifier: "EventCell"
        )
    }
    
}

extension EventsPageVC: UITableViewDataSource, UITableViewDelegate {
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "EventCell",
            for: indexPath
        )
        
        if let eventCell = cell as? EventCell {
            eventCell.configure(with: tableData[indexPath.row])
            //notificationCell.configure(with: tableData[indexPath.section].notifications[indexPath.row])
        }
        
        return cell
    }
    
    
}
