//
//  TaskService.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import Foundation

class TaskService {
    
    private var components = URLComponents()
    
    init() {
        components.scheme = ServerStruct.serverScheme
        components.host = ServerStruct.serverHost
        components.port = ServerStruct.serverPort
    }
    
    func getUserTasks(parameters: [String:String],  completion: @escaping (Result<Tasks, Error>) -> ()) {
        
        components.path = "/getUserTasks"
        
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
                                    let resp = try decoder.decode(Tasks.self, from: data)
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
    
    func getEventTasks(parameters: [String:String],  completion: @escaping (Result<Tasks, Error>) -> ()) {
        
        components.path = "/getEventTasks"
        
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
                                    let resp = try decoder.decode(Tasks.self, from: data)
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
    
    func createNewTask(parameters: [String:String],  completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/createNewTask"
        
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
    
    func doneTask(parameters: [String:String],  completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/doneTask"
        
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
    
}

