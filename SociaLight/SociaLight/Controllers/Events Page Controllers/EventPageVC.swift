//
//  EventPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import JGProgressHUD

class EventPageVC: UIViewController {

    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var eventDescriptionLabel: UILabel!
    @IBOutlet var placeLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    private var service = EventService()
    private let loader = JGProgressHUD()
    
    var eventKey: String!
    var event: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        getEvent()
    }
    
    func setupViews() {}
    
    func getEvent() {
        let parameters = [
            "userId": getUserId(),
            "eventUniqueKey": eventKey!
        ]
        
        showLoader()
        service.getEvent(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loader.dismiss(animated: true)
                switch result {
                case .success(let response):
                    self.handleSuccess(event: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(event: Event) {
        self.event = event
                
        if !event.groupId.isEmpty {
            let addButton = UIBarButtonItem(image: UIImage(systemName: "checklist.rtl"), style: .plain, target: self, action: #selector(navigate))
            self.navigationItem.rightBarButtonItem  = addButton
        }
        
        eventNameLabel.text = event.eventTitle
        eventDescriptionLabel.text = event.eventDescription
        placeLabel.text = event.place
        dateLabel.text = event.date
        timeLabel.text = event.time
    }
    
    func showLoader() {
        loader.textLabel.text = "Loading..."
        loader.style = .light
        loader.backgroundColor = .white.withAlphaComponent(0.5)
        loader.show(in: self.view)
    }
    
    @objc func navigate() {
        if let event = event {
            navigateToTasksPage(eventKey: event.eventUniqueKey, creatorId: event.creatorId, groupId: event.groupId)
        }
    }
    
}
