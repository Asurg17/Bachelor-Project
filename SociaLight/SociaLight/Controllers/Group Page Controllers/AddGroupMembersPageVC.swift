//
//  AddGroupMembersPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.08.22.
//

import UIKit
import KeychainSwift
import SDWebImage

class AddGroupMembersPageVC: UIViewController {
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add Group Members"
        
        checkGroup(group: group)
    }
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
}
