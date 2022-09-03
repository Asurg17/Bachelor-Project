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
    func update(groupTitle: String)
}

protocol UpdateTasksProtocol {
    func update()
}

// --------------Cells & Reusable Views Protocols------------------

protocol NotificationCellDelegate: AnyObject {
    func friendshipAccepted(_ notification: NotificationCell)
    func friendshipRejected(_ notification: NotificationCell)
    func acceptInvitation(_ notification: NotificationCell)
    func rejectInvitation(_ notification: NotificationCell)
    func navigateToGroupPage(groupId: String)
    func navigateToUserPage(userId: String)
}

protocol EventCellDelegate: AnyObject {
    func navigate(eventKey: String)
}

protocol TaskCellProtocol: AnyObject {
    func navigate(eventKey: String)
    func doneTask(_ task: TaskCell)
}

protocol FriendCellDelegate: AnyObject {
    func cellDidClick(_ friend: FriendCell)
}

protocol GroupCellDelegate: AnyObject {
    func cellDidClick(_ group: GroupCell)
}

protocol GroupMemberCellDelegate: AnyObject {
    func sendFriendshipRequest(_ member: GroupMemberCell)
    func userIsClicked(_ member: GroupMemberCell)
}

protocol MediaFileCellDelegate: AnyObject {
    func cellDidClick(_ media: MediaFileCell)
}

protocol GroupInfoActionViewDelegate: AnyObject {
    func actionDidInitiated(_ sender: GroupInfoActionView)
}

protocol ErrorViewDelegate:AnyObject {
    func reload(_ sender: ErrorView)
}

