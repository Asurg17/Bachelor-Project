//
//  Global Constants.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 26.08.22.
//

import UIKit

struct ServerStruct {
    // server data //46.49.35.44:8080
    static let serverScheme: String = "http"
    static let serverHost: String = "localhost" //"46.49.35.44"
    static let serverPort: Int = 8080 //8080
}

// ----------------Constants--------------

struct Constants {
    // Keys
    static let userIdKey: String = "userId"
    static let groupIdKey: String = "groupId"
    static let lastSeenNotificationKey: String = "lastSeenNotification"
    static let admin: String = "A"
    static let member: String = "M"
    static let activeTaskStatus: String = "A"
    static let groupEvent: String = "in_group"
    
    // Warning textst
    static let unspecifiedWarningText: String = "Something went wrong!"
    static let fieldsAreNotFilledWarningText: String = "Please fill all fields!"
    static let requiredFieldsAreNotFilledWarningText: String = "Please fill all required fields!"
    static let passwordDoesNotMatchWarningText: String = "Passwords doesn’t match!"
    static let passwordLengthWarningText: String = "Password should be at least 6 characters long!"
    static let samePasswordsWarningText: String = "Can't use same password!"
    static let noChangesdWarningText: String = "Nothing to change!"
    static let membersCountNotChosenWarningText: String = "Please choose members count!"
    static let groupNameWarningText: String = "You Should Provide Group Name!"
    static let maximalGroupMembersNumberReachedWarningText: String = "Can't add new Member to the Group. Maximal number of members is reached!"
    static let assigneeNotChosenWarningText: String = "Please choose member"
    
    // Error Texts
    static let unspecifiedErrorText: String = "Something went wrong"
    static let getUserInfoErrorText: String = "Can't get user Info"
    static let getUserGroupsErrorText: String = "Can't get user Groups"
    static let getUserFriendsErrorText: String = "Can't get user Friends"
    static let searchGroupsErrorText: String = "Can't serch new Groups"
    static let uploadImageErrorText: String = "Can't upload Image"
    static let changePasswordErrorText: String = "Can't change Password"
    static let saveChangesErrorText: String = "Can't save Changes"
    static let createGroupErrorText: String = "Can't create Group"
    static let sendFriendshipRequestErrorText: String = "Can't send friendship request"
    static let fatalError: String = "Fatal Error!"
    
    static let bottomOffset = 10.0
    // Picker Data
    static let pickerData: [Int] = [2, 3, 4, 5, 10, 20, 25, 50]
    
    // Characters Max Number
    static let usernameCharactersMaxNum = 25
    static let phoneCharactersMaxNum = 15
    static let firstNameCharactersMaxNum = 15
    static let lastNameCharactersMaxNum = 15
    static let groupNameCharactersMaxNum = 50
    static let groupDescriptionCharactersMaxNum = 100
    static let eventNameCharactersMaxNum = 50
    static let eventDescriptionCharactersMaxNum = 150
    static let eventPlaceCharactersMaxNum = 120
    
    static let usernameCharactersMaxNumWarning = "Maximum length of Username is: \(usernameCharactersMaxNum) characters"
    static let phoneCharactersMaxNumWarning = "Maximum length of Phone Number is: \(phoneCharactersMaxNum) characters"
    static let firstNameCharactersMaxNumWarning = "Maximum length of First Name is: \(firstNameCharactersMaxNum) characters"
    static let lastNameCharactersMaxNumWarning = "Maximum length of Last Name is: \(lastNameCharactersMaxNum) characters"
    static let groupNameCharactersMaxNumWarning = "Maximum length of Group Name is: \(groupNameCharactersMaxNum) characters"
    static let groupDescriptionCharactersMaxNumWarning = "Maximum length of Group Desctiption is: \(groupDescriptionCharactersMaxNum) characters"
    static let eventNameCharactersMaxNumWarning = "Maximum length of Event Name is: \(eventNameCharactersMaxNum) characters"
    static let eventDescriptionCharactersMaxNumWarning = "Maximum length of Event Desctiption is: \(eventDescriptionCharactersMaxNum) characters"
    static let eventPlaceCharactersMaxNumWarning = "Maximum length of Event Place is: \(eventPlaceCharactersMaxNum) characters"
    
    // Table&Collection View Parameters
    static let itemCountInLine: CGFloat = 3
    static let spacing: CGFloat = 10.0
    static let lineSpacing: CGFloat = 20.0
    static let topBottomSpacing: CGFloat = 20.0
    static let additionalSpacing: CGFloat = 20.0
    static let tableRowHeight = 80.0
    static let tableHeaderHeight = 44.0
    static let tableViewOffset = 32.0
    static let itemCount: CGFloat = 4
    
    // Messages
    static let maimumRecordTime = 29.0
    static let mediaFileCellOffset = 3.0
    static let messageMaxPartNum = 10.0
    static let audioMessageMinWidth = 100.0
    static let audioMessageHeight = 40.0
    static let messageWidthMultiplier = 0.7
    static let messageHeightMultiplier = 0.35
    static let messagesCornerRadius = 15.0
    
    //
    static let mainWsEndpoint: String = "/mainWsEndpoint?userId="
    static let messagesWsEndpoint: String = "/messagesWsEndpoint?userId="
    
    static let getImageURLPrefix: String = ServerStruct.serverScheme + "://" + ServerStruct.serverHost + ":" + ServerStruct.serverPort.description + "/getImage?imageKey="
    static let getAudioURLPrefix: String = ServerStruct.serverScheme + "://" + ServerStruct.serverHost + ":" + ServerStruct.serverPort.description + "/getAudio?audioKey="
    
    static let userImagePrefix: String = "userImage"
    static let groupImagePrefix: String = "groupImage"
    
    
    // Notification keys
    static let friendshipRequestNotificationKey = "friendship_request"
    static let groupInvitationNotificationKey = "group_invitation"
    static let defaultNotificationKey = "default"
}


