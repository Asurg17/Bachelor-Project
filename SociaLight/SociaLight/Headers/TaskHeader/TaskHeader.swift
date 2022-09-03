//
//  TaskHeader.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit

class TaskHeaderModel {
    var title: String
    
    init(title: String){
        self.title = title
    }
}

class TaskHeader: UITableViewHeaderFooterView {
    @IBOutlet var headerTitleLabel: UILabel!
     
    func configure(with model: TaskHeaderModel){
        headerTitleLabel.text = model.title
    }
}
