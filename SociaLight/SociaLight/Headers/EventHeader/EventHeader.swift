//
//  EventHeader.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 25.08.22.
//

import UIKit

class EventHeaderModel {
    var title: String
    
    init(title: String){
        self.title = title
    }
}

class EventHeader: UITableViewHeaderFooterView {
    @IBOutlet var headerTitleLabel: UILabel!
     
    func configure(with model: EventHeaderModel){
        headerTitleLabel.text = model.title
    }
}
