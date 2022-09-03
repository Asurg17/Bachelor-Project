//
//  SignInUpService.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import Foundation

class SignInUpService {
    
    private let apiKey = ""
    private var components = URLComponents()
    
    init() {
        components.scheme = ServerStruct.serverScheme
        components.host = ServerStruct.serverHost
        components.port = ServerStruct.serverPort
    }

    func registerNewUser(
        username: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> ()
    ) {
        
        components.path = "/registerNewUser"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "username": username,
                "firstName": firstName,
                "lastName": lastName,
                "phoneNumber": phoneNumber,
                "password": password
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
                                    let resp = try decoder.decode(UserIdResponse.self, from: data)
                                    completion(.success(resp.userId))
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
    
    func validateUser(username: String, password: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/validateUser"
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters = [
                "username": username,
                "password": password
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
                                    let resp = try decoder.decode(UserIdResponse.self, from: data)
                                    completion(.success(resp.userId))
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
