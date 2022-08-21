//
//  GroupMediaFilesPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.08.22.
//

import UIKit
import SDWebImage

class GroupMediaFilesPageVC: UIViewController {
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group Media Files"
        
        checkGroup(group: group)
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
}
