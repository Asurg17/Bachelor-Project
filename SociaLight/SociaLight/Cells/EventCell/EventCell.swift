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
    var eventType: String
    var groupId: String
    var groupImageURL: String
    var groupTitle: String
    var groupDescription: String
    var groupCapacity: String
    var membersCount: String
    var image: UIImage
    
    weak var delegate: EventCellDelegate?

    init(eventUniqueKey: String, fromUserId: String, fromUserWholeName: String, fromUserImageURL: String, eventType: String, groupId: String, groupImageURL: String, groupTitle: String, groupDescription: String, groupCapacity: String, membersCount: String, delegate: EventCellDelegate?) {
        self.eventUniqueKey = eventUniqueKey
        self.fromUserId = fromUserId
        self.fromUserWholeName = fromUserWholeName
        self.fromUserImageURL = fromUserImageURL
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
    
    var model: EventCellModel!

    @IBOutlet private var eventImageView: UIImageView!
    @IBOutlet private var eventHeaderLabel: UILabel!
    @IBOutlet private var eventDescriptionLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    
    func configure(with text: String) {
        eventDescriptionLabel.text = text
    }
        
    @IBAction func navigate() {
//        if model.isMeetingEvent {
//            model.delegate?.navigateToGroupPage(self)
//        } else {
//            model.delegate?.navigateToGroupPage(self)
//        }
    }
    
}
