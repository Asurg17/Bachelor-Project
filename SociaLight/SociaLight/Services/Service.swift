//
//  Service.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 30.04.22.
//

import Foundation

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
                            if let bytes = data {
                                completion(.success(String(bytes: bytes, encoding: .utf8)!))
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [NSLocalizedDescriptionKey: "Internal error!"]
                                                           )))
                            }
                        } else {
                            print(httpUrlResponse.value(forHTTPHeaderField: "Error") ?? "")
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
    
    func checkUser(username: String, password: String, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/checkUser"
        
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
                            if let bytes = data {
                                completion(.success(String(bytes: bytes, encoding: .utf8)!))
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
                                    let response = try decoder.decode(UserInfoResponse.self, from: data)
                                    completion(.success(response))
                                    
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
    
}
