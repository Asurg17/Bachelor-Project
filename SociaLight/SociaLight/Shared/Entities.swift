//
//  Entities.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import Foundation

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

// -------------UserGroups--------------

struct UserGroups: Codable {
    let groups: [UserGroup]
}

struct UserGroup: Codable {
    let groupId: String
    let groupTitle: String
    let groupDescription: String
}

struct UserFriends: Codable {
    let freinds: [UserFriend]
}

struct UserFriend: Codable {
    let friendId: String
    let friendFirstName: String
    let friendLastName: String
    let friendPhone: String
}
