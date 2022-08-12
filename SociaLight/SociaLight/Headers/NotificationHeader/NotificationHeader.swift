//
//  NotificationHeader.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 09.08.22.
//

import UIKit

class NotificationHeaderModel {
    var title: String
    
    init(title: String){
        self.title = title
    }
}

class NotificationHeader: UITableViewHeaderFooterView {
    
    @IBOutlet var headerTitleLabel: UILabel!
     
    func configure(with model: NotificationHeaderModel){
        headerTitleLabel.text = model.title
    }
    
}
