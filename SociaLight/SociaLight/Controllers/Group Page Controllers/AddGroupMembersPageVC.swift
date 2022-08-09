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
        
        checkGroup()
    }
    
    func checkGroup() {
        guard let _ = group else {
            showWarningAlert(warningText: "Something Went Wrong!")
            return //maybe only back button has to be active (need to add global error views)
        }
    }
    
    
    @IBAction func back() {
        navigationController?.popViewController(animated: true)
    }
}
