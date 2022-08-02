//
//  Protocols.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.05.22.
//

import Foundation

protocol DismissProtocol {
    func refresh()
}

protocol UpdateGroup {
    func update(updatedGroup: Group)
}

// --------------Cells & Reusable Views Protocols------------------

protocol FriendCellDelegate: AnyObject {
    func cellDidClick(_ friend: FriendCell)
}

protocol GroupCellDelegate: AnyObject {
    func cellDidClick(_ friend: GroupCell)
}

protocol GroupInfoActionViewDelegate: AnyObject {
    func actionDidInitiated(_ sender: GroupInfoActionView)
}
