//
//  TaskCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit

class TaskCellModel {
    var assigneeId: String
    var assigneeName: String
    var eventKey: String
    var taskTitle: String
    var date: String
    var time: String
    var taskId: String
    var taskStatus: String
    var currentUserId: String
    var isUserTasksPage: Bool
    
    weak var delegate: TaskCellProtocol?

    init(assigneeId: String, assigneeName: String, eventKey: String, taskTitle: String, date: String, time: String, taskId: String, taskStatus: String, currentUserId: String, isUserTasksPage: Bool, delegate: TaskCellProtocol?) {
        self.assigneeId = assigneeId
        self.assigneeName = assigneeName
        self.eventKey = eventKey
        self.taskTitle = taskTitle
        self.date = date
        self.time = time
        self.taskId = taskId
        self.taskStatus = taskStatus
        self.currentUserId = currentUserId
        self.isUserTasksPage = true
        self.delegate = delegate
    }
}

class TaskCell: UITableViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var taskImageView: UIImageView!
    @IBOutlet private var assigneeNameLabel: UILabel!
    @IBOutlet private var taskLabel: UILabel!
    @IBOutlet private var timeLabel: UILabel!
    @IBOutlet private var checkboxOuterView: UIView!
    @IBOutlet private var checkImage: UIImageView!
    @IBOutlet private var doneButton: UIButton!
    

    var model: TaskCellModel!

    func configure(with model: TaskCellModel) {
        self.model = model
                
        assigneeNameLabel.text = model.assigneeName
        taskLabel.text = model.taskTitle
        timeLabel.text = model.time
        
        taskImageView.sd_setImage(
            with: URL(string: (Constants.getImageURLPrefix + Constants.userImagePrefix + model.assigneeId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
            completed: { (image, error, cacheType, imageURL) in
                if image == nil {
                    self.taskImageView.image = UIImage(named: "empty_avatar_image")
                }
            }
        )
        
        checkIfTaskIsDone()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = subviews[0].frame.width
        for view in subviews where view != contentView {
            if view.frame.width == width {
                view.removeFromSuperview()
            }
        }
    }
    
    func checkIfTaskIsDone() {
        checkImage.isHidden = (model.taskStatus == Constants.activeTaskStatus)
        doneButton.isHidden = (model.taskStatus != Constants.activeTaskStatus) || (model.assigneeId != model.currentUserId)
    }
    
    @IBAction func handleCellClick() {
        if model.taskStatus == Constants.activeTaskStatus {
            model.delegate?.doneTask(self)
        }
    }
    
    @IBAction func navigateToEventPage() {
        model.delegate?.navigate(eventKey: model.eventKey)
    }
}

