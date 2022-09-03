//
//  EventCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventCellModel {
    var eventUniqueKey: String
    var creatorId: String
    var toUserId: String
    var groupId: String
    var eventHeader: String
    var eventTitle: String
    var eventDescription: String
    var place: String
    var eventType: String
    var date: String
    var time: String
    
    weak var delegate: EventCellDelegate?

    init(eventUniqueKey: String, creatorId: String, toUserId: String, groupId: String, eventHeader: String, eventTitle: String, eventDescription: String, place: String, eventType: String, date: String, time: String, delegate: EventCellDelegate?) {
        self.eventUniqueKey = eventUniqueKey
        self.creatorId = creatorId
        self.toUserId = toUserId
        self.groupId = groupId
        self.eventHeader = eventHeader
        self.eventTitle = eventTitle
        self.eventDescription = eventDescription
        self.place = place
        self.eventType = eventType
        self.date = date
        self.time = time
        self.delegate = delegate
    }
}

class EventCell: UITableViewCell {

    @IBOutlet private var eventImageView: UIImageView!
    @IBOutlet private var eventHeaderLabel: UILabel!
    @IBOutlet private var eventTitleLabel: UILabel!
    @IBOutlet private var placeLabel: UILabel!
    @IBOutlet private var eventDescriptionLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    
    var model: EventCellModel!

    func configure(with model: EventCellModel) {
        self.model = model
                
        eventHeaderLabel.text = model.eventHeader
        eventTitleLabel.text = model.eventTitle
        placeLabel.text = model.place
        eventDescriptionLabel.text = model.eventDescription
        timeLabel.text = model.time
        
        var imageKey = model.creatorId
        if !model.toUserId.isEmpty {
            imageKey = model.toUserId
        }
        
        var imageURL = URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + imageKey).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        var placeholderImage = UIImage(named: "empty_avatar_image")
        if model.eventType == Constants.groupEvent {
            imageURL = URL(string: (Constants.getImageURLPrefix + Constants.groupImagePrefix + model.groupId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            placeholderImage = UIImage(named: "GroupIcon")
        }
        
        eventImageView.sd_setImage(
            with: imageURL,
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.eventImageView.image = placeholderImage
                }
            }
        )
    }
        
    @IBAction func navigate() {
        model.delegate?.navigate(eventKey: model.eventUniqueKey)
    }
    
}
