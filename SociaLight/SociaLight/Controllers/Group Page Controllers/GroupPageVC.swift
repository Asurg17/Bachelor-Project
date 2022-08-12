//
//  GroupPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.07.22.
//

import UIKit
import KeychainSwift
import SDWebImage

class GroupPageVC: UIViewController {
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group"
        
        setupViews()
        checkGroup(group: group)
    }
    
    func setupViews() {
        
    }
    
    func navigateToGrouInfopPage(group: Group) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupInfoPagePageController = storyBoard.instantiateViewController(withIdentifier: "GroupInfoPageVC") as! GroupInfoPageVC
        groupInfoPagePageController.delegate = self
        groupInfoPagePageController.group = group
        self.navigationController?.pushViewController(groupInfoPagePageController, animated: true)
    }
    
    @IBAction func showGroupInfo() {
        navigateToGrouInfopPage(group: group!)
    }
    
    @IBAction func back() {
        navigationController?.popToRootViewController(animated: true)
    }
    
}

extension GroupPageVC: UpdateGroup {
    
    func update(updatedGroup: Group) {
        self.group = updatedGroup
    }
    
}
