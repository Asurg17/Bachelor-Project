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
        completion: @escaping (Result<String, Error>) -> ()
    ) {
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
                            print(data)
                            completion(.success(""))
                        } else {
                            if (httpUrlResponse.value(forHTTPHeaderField: "Error") ?? "").contains("duplicate key") {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [ NSLocalizedDescriptionKey: "Such username already exists!"]
                                                           )))
                            } else {
                                completion(.failure(NSError(domain: "",
                                                            code: 400,
                                                            userInfo: [ NSLocalizedDescriptionKey: "Can't register new user!"]
                                                           )))
                            }
                        }
                    } else {
                       completion(.failure(NSError(domain: "",
                                                   code: 400,
                                                   userInfo: [ NSLocalizedDescriptionKey: "Bad response!"]
                                                  )))
                    }
                })
            task.resume()
        } else {
            completion(.failure(ServiceError.invalidParameters))
        }
        
    }
    
    
    
}
