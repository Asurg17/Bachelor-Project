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
    
    var groupId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        
    }
    
    @IBAction func back() {
        navigationController?.popToRootViewController(animated: true)
    }
    
}
