//
//  GroupMediaFilesPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 01.08.22.
//

import UIKit
import KeychainSwift
import SDWebImage

class GroupMediaFilesPageVC: UIViewController {
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkGroup()
    }
    
    func checkGroup() {
        guard let _ = group else {
            showWarningAlert(warningText: "Something Went Wrong!")
            return //maybe only back button has to be active (need to add global error views)
        }
    }
}
