//
//  EventHeader.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventHeader: UITableViewHeaderFooterView {

    @IBOutlet var headerTitleLabel: UILabel!
     
    func configure(with model: NotificationHeaderModel){
        headerTitleLabel.text = model.title
    }
}
