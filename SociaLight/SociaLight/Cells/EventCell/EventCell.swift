//
//  EventCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventCellModel {
    var eventUniqueKey: String
    var fromUserId: String
    var fromUserWholeName: String
    var fromUserImageURL: String
    var userRole: String
    var eventType: String
    var groupId: String
    var groupImageURL: String
    var groupTitle: String
    var groupDescription: String
    var groupCapacity: String
    var membersCount: String
    var image: UIImage
    
    weak var delegate: EventCellDelegate?

    init(eventUniqueKey: String, fromUserId: String, fromUserWholeName: String, fromUserImageURL: String, userRole: String, eventType: String, groupId: String, groupImageURL: String, groupTitle: String, groupDescription: String, groupCapacity: String, membersCount: String, delegate: EventCellDelegate?) {
        self.eventUniqueKey = eventUniqueKey
        self.fromUserId = fromUserId
        self.fromUserWholeName = fromUserWholeName
        self.fromUserImageURL = fromUserImageURL
        self.userRole = userRole
        self.eventType = eventType
        self.groupId = groupId
        self.groupImageURL = groupImageURL
        self.groupTitle = groupTitle
        self.groupDescription = groupDescription
        self.groupCapacity = groupCapacity
        self.membersCount = membersCount
        self.image = UIImage()
        self.delegate = delegate
    }
}

class EventCell: UITableViewCell {

    @IBOutlet private var eventImageView: UIImageView!
    @IBOutlet private var eventHeaderLabel: UILabel!
    @IBOutlet private var eventDescriptionLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    
    var model: EventCellModel!
    
    func configure(with model: EventCellModel) {
        self.model = model
        
        
    }
        
    @IBAction func navigate() {
//        if model.isMeetingEvent {
//            model.delegate?.navigateToGroupPage(self)
//        } else {
//            model.delegate?.navigateToGroupPage(self)
//        }
    }
    
}
