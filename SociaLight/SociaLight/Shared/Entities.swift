//
//  Entities.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import Foundation
import UIKit
import MessageKit
import CoreLocation

struct ServiceResponse {
    let response: String
    let warning: String
    let isWarning: Bool
}

// -------------UserId---------------

struct UserIdResponse: Codable {
    let userId: String
}

// -------------UserInfo--------------

struct UserInfoResponse: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let gender: String
    let age: String
    let location: String
    let birthDate: String
    let phone: String
}

// -------------UserGroups-------------

struct UserGroups: Codable {
    let groups: [UserGroup]
}

struct UserGroup: Codable {
    let groupId: String
    let groupTitle: String
    let groupDescription: String
    let groupCapacity: String
    let groupMembersNum: String
}

// -----------Friends-------------------

struct UserFriends: Codable {
    let friends: [UserFriend]
}

struct UserFriend: Codable {
    let friendId: String
    let friendFirstName: String
    let friendLastName: String
    let friendPhone: String
}

// -------------Group------------------


struct Group {
    var groupId: String
    var groupImage: UIImage
    var membersCurrentNumber: Int
    var membersMaxNumber: Int
    var groupName: String
    var groupDescription: String
    var isPrivate: Bool
}

struct GroupMembers: Codable {
    let members: [GroupMember]
}

struct GroupMember: Codable {
    let memberId: String
    let memberFirstName: String
    let memberLastName: String
    let memberPhone: String
    let isFriendRequestAlreadySent: String
    let areAlreadyFriends: String
}

// -----------Create Group Request & Response-------------

struct CreateGroupResponse: Codable {
    let groupId: String
}

struct CreateGroupRequest {
    let groupName: String
    let groupDescription: String
    let membersCount: String
    let isPrivate: String
    let userId: String
}


// -----------------Notifications-----------------

struct Notifications: Codable {
    let notifications: [Notification]
}

struct Notification: Codable {
    let requestUniqueKey: String
    let fromUserId: String
    let fromUserWholeName: String
    let isFriendshipRequest: String
    let groupId: String
    let groupTitle: String
    let groupDescription: String
    let groupCapacity: String
    let membersCount: String
}

// Medial Files

struct MediaFiles: Codable {
    let mediaFiles: [MediaFile]
}

struct MediaFile: Codable {
    let imageURL: String
}

// Messages

struct GroupMessages: Codable {
    let messages: [GroupMessage]
}

struct GroupMessage: Codable {
    let senderId: String
    let senderName: String
    let messageId: String
    let sentDate: String
    let messageType: String
    let content: String
    let sendDateTimestamp: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sentDateTimestamp: String
}

struct Sender: SenderType {
    var imageURL: String
    var senderId: String
    var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Audio: AudioItem {
    var url: URL
    var duration: Float
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
