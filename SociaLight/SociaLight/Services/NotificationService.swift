//
//  NotificationService.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import Foundation


class NotificationService {
    
    private let apiKey = ""
    private var components = URLComponents()
    
    init() {
        components.scheme = ServerStruct.serverScheme
        components.host = ServerStruct.serverHost
        components.port = ServerStruct.serverPort
    }
    
    func checkForNewNotifications(parameters: [String: String], completion: @escaping (Result<CheckForNewNotificationsResponse, Error>) -> ()) {
        
        components.path = "/checkForNewNotifications"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
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
                                    let resp = try decoder.decode(CheckForNewNotificationsResponse.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func getUserNotifications(parameters: [String: String], completion: @escaping (Result<Notifications, Error>) -> ()) {
        
        components.path = "/getUserNotifications"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
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
                                    let resp = try decoder.decode(Notifications.self, from: data)
                                    completion(.success(resp))
                                } catch {
                                    completion(.failure(error))
                                }
                            } else {
                                completion(.failure(ServiceError.noData))
                            }
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func acceptFriendshipRequest(userId: String, fromUserId: String, requestUniqueKey: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/acceptFriendshipRequest"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "fromUserId": fromUserId,
                "requestUniqueKey": requestUniqueKey
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success(""))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func rejectFriendshipRequest(userId: String, requestUniqueKey: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/rejectFriendshipRequest"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "requestUniqueKey": requestUniqueKey
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success(""))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func acceptInvitation(userId: String, fromUserId: String, groupId: String, requestUniqueKey: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/acceptInvitation"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "fromUserId": fromUserId,
                "groupId": groupId,
                "requestUniqueKey": requestUniqueKey
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success(""))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func rejectInvitation(userId: String, requestUniqueKey: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/rejectInvitation"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "requestUniqueKey": requestUniqueKey
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success(""))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func sendFriendshipRequest(fromUserId: String, toUserId: String, groupId: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/sendFriendshipRequest"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "fromUserId": fromUserId,
                "toUserId": toUserId,
                "groupId": groupId
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                completion(.failure(error))
            }
            
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    if let httpUrlResponse = response as? HTTPURLResponse {
                        if httpUrlResponse.statusCode == 200 {
                            completion(.success("Send"))
                        } else {
                            completion(.failure(NSError(domain: "",
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
    
    func sendGroupInvitations(userId: String,
                              groupId: String,
                              members: Array<String>,
                              completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/sendGroupInvitations"
        
        let parameters = [
            "userId": userId,
            "groupId": groupId
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            var request = URLRequest(url: url)
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
                                                        code: httpUrlResponse.statusCode,
                                                        userInfo: [NSLocalizedDescriptionKey: httpUrlResponse.value(forHTTPHeaderField: "Error") ?? Constants.unspecifiedErrorText]
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
