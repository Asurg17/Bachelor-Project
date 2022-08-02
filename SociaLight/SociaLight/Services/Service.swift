//
//  Service.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 30.04.22.
//

import Foundation
import UIKit

class Service {
    
    private let apiKey = ""
    private var components = URLComponents()
    
    init() {
        components.scheme = "http"
        components.host = "localhost"
        components.port = 9000
    }
    
    func registerNewUser(
        username: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/registerClient"
        
        let parameters = [
            "username": username,
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "password": password
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserIdResponse.self, from: data)
                                    completion(.success(resp.userId))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Internal error!"]
                                                           )))
                            }
                        } else {
                            if (httpUrlResponse.value(forHTTPHeaderField: "Error") ?? "").contains("duplicate key") {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Such username already exists!"]
                                                           )))
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Can't register new user!"]
                                                           )))
                            }
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
        
    }
    
    func validateUser(username: String, password: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/validateUser"
        
        let parameters = [
            "username": username,
            "password": password
        ]
    
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserIdResponse.self, from: data)
                                    completion(.success(resp.userId))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Internal error!"]
                                                           )))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    
    }
    
    func getUserInfo(userId: String, completion: @escaping (Result<UserInfoResponse, Error>) -> ()) {
        
        components.path = "/getUserInfo"
        
        let parameters = [
            "userId": userId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserInfoResponse.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func getUserGroups(userId: String, completion: @escaping (Result<UserGroups, Error>) -> ()) {
        
        components.path = "/getUserGroups"
        
        let parameters = [
            "userId": userId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserGroups.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func getUserFriends(userId: String, completion: @escaping (Result<UserFriends, Error>) -> ()) {
        
        components.path = "/getUserFriends"
        
        let parameters = [
            "userId": userId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserFriends.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func searchNewGroups(userId: String, groupIdentifier: String, completion: @escaping (Result<UserGroups, Error>) -> ()) {
        
        components.path = "/searchNewGroups"
        
        let parameters = [
            "userId": userId,
            "groupIdentifier": groupIdentifier
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(UserGroups.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func changePassword(userId: String,
                        oldPassword: String,
                        newPassword: String,
                        completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/changePassword"
        
        let parameters = [
            "userId": userId,
            "oldPassword": oldPassword,
            "newPassword": newPassword
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Password was changed successfully!"))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func changePersonalInfo(userId: String,
                            age: String,
                            phoneNumber: String,
                            birthDate: String,
                            completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/changePersonalInfo"
        
        let parameters = [
            "userId": userId,
            "age": age,
            "phoneNumber": phoneNumber,
            "birthDate": birthDate
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Changes saved successfully!"))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func uploadImage(imageKey: String, image: UIImage, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/uploadImage"
        
        let parameters = [
            "imageKey": imageKey
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = image.pngData()
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Image changed successfully!"))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func createGroup(requestParams: CreateGroupRequest,
                     completion: @escaping (Result<CreateGroupResponse, Error>) -> ()) {
        
        components.path = "/createGroup"
        
        let parameters = [
            "groupName": requestParams.groupName,
            "groupDescription": requestParams.groupDescription,
            "membersCount": requestParams.membersCount,
            "isPrivate": requestParams.isPrivate,
            "userId": requestParams.userId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(CreateGroupResponse.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            if (httpUrlResponse.value(forHTTPHeaderField: "Error") ?? "").contains("duplicate key") {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "You have already created group with such name. Please choose another name and try again!"]
                                                           )))
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Can't create new Group!"]
                                                           )))
                            }
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func addGroupMembers(userId: String,
                         groupId: String,
                         members: Array<String>,
                         completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/addGroupMembers"
        
        let parameters = [
            "userId": userId,
            "groupId": groupId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let jsonObject: NSMutableDictionary = NSMutableDictionary()
            var jsonData: Data  = Data()
            jsonObject.setValue(members, forKey: "members")
            
            do {
                jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            } catch {
                completion(.failure(NSError(domain: "",
                                            code: 400,
                                            userInfo: [NSLocalizedDescriptionKey: "Can't get Json Data"]
                                           )))
            }
            
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("OK!"))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: 400,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                       )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func saveGroupUpdates(userId: String,
                          groupId: String,
                          groupName: String,
                          groupDescription: String,
                          completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/saveGroupUpdates"
        
        let parameters = [
            "userId": userId,
            "groupId": groupId,
            "groupName": groupName,
            "groupDescription": groupDescription
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Changes saved successfully!"))
                        } else {
                            if (httpUrlResponse.value(forHTTPHeaderField: "Error") ?? "").contains("duplicate key") {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "You already have group with such name. Please choose another name and try again!"]
                                                           )))
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                           )))
                            }
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
    func leaveGroup(userId: String,
                    groupId: String,
                    completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/leaveGroup"
        
        let parameters = [
            "userId": userId,
            "groupId": groupId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Group leaved :("))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                         code: 400,
                                                         userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? ""]
                                                        )))
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
    }
    
}
