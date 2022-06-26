//
//  FriendCell.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 23.06.22.
//

import UIKit

class FriendCellModel {
    var friendId: String
    var friendFristName: String
    var friendLastName: String
    var friendPhone: String
    var isSelected: Bool
    
    weak var delegate: FriendCellDelegate?

    init(friendId: String, friendFristName: String, friendLastName: String, friendPhone: String, isSelected: Bool, delegate: FriendCellDelegate?) {
        self.friendId = friendId
        self.friendFristName = friendFristName
        self.friendLastName = friendLastName
        self.friendPhone = friendPhone
        self.isSelected = isSelected
        self.delegate = delegate
    }
}

protocol FriendCellDelegate: AnyObject {
    func cellDidClick(_ friend: FriendCell)
}

class FriendCell: UITableViewCell {
    
    @IBOutlet private var imageOuterView: UIView!
    @IBOutlet private var friendImage: UIImageView!
    @IBOutlet private var friendName: UILabel!
    @IBOutlet private var friendPhone: UILabel!
    @IBOutlet private var checkboxOuterView: UIView!
    @IBOutlet private var checkboxInnerView: UIView!

    var model: FriendCellModel!
    
    func configure(with model: FriendCellModel){
        self.model = model
        
        friendName.text = model.friendFristName + " " + model.friendLastName
        friendPhone.text = model.friendPhone
        
        checkIfCellIsSelected()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = subviews[0].frame.width
        for view in subviews where view != contentView {
            if view.frame.width == width {
                view.removeFromSuperview()
            }
        }
        
        checkboxInnerView.layer.cornerRadius = checkboxInnerView.frame.size.width / 2
        
        checkboxOuterView.layer.borderWidth = 1
        checkboxOuterView.layer.borderColor = UIColor.gray.cgColor
        checkboxOuterView.layer.cornerRadius = checkboxOuterView.frame.size.width / 2
        
        imageOuterView.layer.borderWidth = 1.25
        imageOuterView.layer.borderColor = UIColor.random().cgColor
        imageOuterView.layer.cornerRadius = imageOuterView.frame.size.width / 2
    }
    
    func checkIfCellIsSelected() {
        if model.isSelected {
            checkboxInnerView.isHidden = false
        } else {
            checkboxInnerView.isHidden = true
        }
    }
    
    @IBAction func handleCellClick() {
        model.isSelected.toggle()

        checkIfCellIsSelected()

        model.delegate?.cellDidClick(self)
    }
    
}
