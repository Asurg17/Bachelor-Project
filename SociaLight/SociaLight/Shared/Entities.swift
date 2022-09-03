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

struct UserIdResponse: Codable {
    let userId: String
}

// Group

struct GetGroupTitleResponse: Codable {
    let groupTitle: String
}

struct GetGroupTitleAndDescriptionResponse: Codable {
    let groupTitle: String
    let groupDescription: String
    let userRole: String
}

// UserInfo

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

// UserGroups

struct UserGroups: Codable {
    let groups: [UserGroup]
}

struct UserGroup: Codable {
    let groupId: String
    let groupTitle: String
    let groupDescription: String
    let groupCapacity: String
    let groupMembersNum: String
    let userRole: String
}

// Friends

struct UserFriends: Codable {
    let friends: [UserFriend]
}

struct UserFriend: Codable {
    let friendId: String
    let friendFirstName: String
    let friendLastName: String
    let friendPhone: String
}

// Group


struct Group {
    var groupId: String
    var groupImage: UIImage
    var membersCurrentNumber: Int
    var membersMaxNumber: Int
    var groupName: String
    var groupDescription: String
    var isPrivate: Bool
    var userRole: String
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
    let userRole: String
}

// Create Group Request & Response

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


// Notifications

struct Notifications: Codable {
    let notifications: [Notification]
}

struct Notification: Codable {
    var requestUniqueKey: String
    var fromUserId: String
    var notificationTitle: String
    var notificationText: String
    var notificationType: String
    var groupId: String
    var groupTitle: String
    var groupDescription: String
    var groupCapacity: String
    var membersCount: String
    var sendDate: String
    var sendTime: String
}

// Medial Files

struct MediaFiles: Codable {
    let mediaFiles: [MediaFile]
}

struct MediaFile: Codable {
    let imageURL: String
    let messageId: String
}

// New Event

struct NewEvent {
    let creatorUserId: String
    let toUserId: String?
    let groupId: String?
    let eventName: String
    let eventDescription: String?
    let place: String
    let dateString: String
    let timeString: String?
    let eventDate: String
    let eventUniqueKey: String
}

// Messages

struct GetCollectionMessagesResp {
    let collectionMessages: [Message]
    let containsMyMessages: Bool
}

struct GroupMessages: Codable {
    let messages: [GroupMessage]
}

struct GroupMessage: Codable {
    let messageUniqueKey: String
    let senderId: String
    let senderName: String
    let messageId: String
    let sentDate: String
    let messageType: String
    let content: String
    let sendDateTimestamp: String
    let duration: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageUniqueKey: String
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var sentDateTimestamp: String
    var duration: Double
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

// Events

struct Events: Codable {
    let events: [Event]
}

struct Event: Codable {
    let eventUniqueKey: String
    let creatorId: String
    let toUserId: String
    let groupId: String
    let eventHeader: String
    let eventTitle: String
    let eventDescription: String
    let place: String
    let eventType: String
    let date: String
    let time: String
}

// Tasks

struct Tasks: Codable {
    let tasks: [Task]
}

struct Task: Codable {
    let assigneeId: String
    let assigneeName: String
    let eventKey: String
    let taskTitle: String
    let date: String
    let time: String
    let taskId: String
    let taskStatus: String
}
