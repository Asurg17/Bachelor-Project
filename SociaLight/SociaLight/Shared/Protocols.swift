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

protocol NotificationCellDelegate: AnyObject {
    func friendshipAccepted(_ notification: NotificationCell)
    func friendshipRejected(_ notification: NotificationCell)
}

protocol FriendCellDelegate: AnyObject {
    func cellDidClick(_ friend: FriendCell)
}

protocol GroupCellDelegate: AnyObject {
    func cellDidClick(_ group: GroupCell)
}

protocol GroupMemberCellDelegate: AnyObject {
    func cellDidClick(_ member: GroupMemberCell)
}

protocol GroupInfoActionViewDelegate: AnyObject {
    func actionDidInitiated(_ sender: GroupInfoActionView)
}
