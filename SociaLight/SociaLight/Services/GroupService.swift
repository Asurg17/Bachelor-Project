//
//  GroupService.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 30.04.22.
//

import UIKit
import Foundation

class GroupService {
    
    private let apiKey = ""
    private var components = URLComponents()
    
    init() {
        components.scheme = ServerStruct.serverScheme
        components.host = ServerStruct.serverHost
        components.port = ServerStruct.serverPort
    }
    
    func searchNewGroups(userId: String, groupIdentifier: String, completion: @escaping (Result<UserGroups, Error>) -> ()) {
        
        components.path = "/searchNewGroups"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "groupIdentifier": groupIdentifier
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
    
    func createGroup(requestParams: CreateGroupRequest,
                     completion: @escaping (Result<CreateGroupResponse, Error>) -> ()) {
        
        components.path = "/createGroup"
    
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": requestParams.userId,
                "groupName": requestParams.groupName,
                "groupDescription": requestParams.groupDescription,
                "membersCount": requestParams.membersCount,
                "isPrivate": requestParams.isPrivate
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
    
    func getGroupTitle(parameters: [String:String], completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/getGroupTitle"

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
                                    let resp = try decoder.decode(GetGroupTitleResponse.self, from: data)
                                    completion(.success(resp.groupTitle))
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
    
    func getGroupTitleAndDescription(parameters: [String:String], completion: @escaping (Result<GetGroupTitleAndDescriptionResponse, Error>) -> ()) {
        
        components.path = "/getGroupTitleAndDescription"

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
                                    let resp = try decoder.decode(GetGroupTitleAndDescriptionResponse.self, from: data)
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
    
    func saveGroupUpdates(userId: String,
                          groupId: String,
                          groupName: String,
                          groupDescription: String,
                          completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/saveGroupUpdates"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
                "groupId": groupId,
                "groupName": groupName,
                "groupDescription": groupDescription
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
                            completion(.success("Changes saved successfully!"))
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
    
    

    func getGroupMembers(userId: String, groupId: String, completion: @escaping (Result<GroupMembers, Error>) -> ()) {
        
        components.path = "/getGroupMembers"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "userId": userId,
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
                            if let data = data {
                                let decoder = JSONDecoder()
                                do {
                                    let resp = try decoder.decode(GroupMembers.self, from: data)
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
    
    func getGroupMediaFiles(parameters: [String:String],  completion: @escaping (Result<MediaFiles, Error>) -> ()) {
        
        components.path = "/getGroupMediaFiles"
        
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
                                    let resp = try decoder.decode(MediaFiles.self, from: data)
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
    
}
