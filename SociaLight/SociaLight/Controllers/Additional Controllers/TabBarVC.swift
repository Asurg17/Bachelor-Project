//
//  TabBarController.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 07.05.22.
//

import UIKit

class TabBarVC: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationItem.hidesBackButton = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

}
