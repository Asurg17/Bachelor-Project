//
//  Entities.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 15.05.22.
//

import Foundation


struct UserInfoResponse: Codable {
    var username: String
    var firstName: String
    var lastName: String
    var gender: String
    var age: String
    var location: String
    var birthDate: String
    var phone: String
}
