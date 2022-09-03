//
//  FileService.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 02.09.22.
//

import UIKit
import Foundation

class FileService {
    
    private let apiKey = ""
    private var components = URLComponents()
    
    init() {
        components.scheme = ServerStruct.serverScheme
        components.host = ServerStruct.serverHost
        components.port = ServerStruct.serverPort
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
    
    func uploadAudio(audioKey: String, audioData: Data, duration: Double, completion: @escaping (Result<String, Error>) -> ()) {
        
        components.path = "/uploadAudio"
        
        let parameters = [
            "audioKey": audioKey,
            "duration": duration.description
        ]
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = audioData
            
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
    
    func getAudio(parameters: [String:String], completion: @escaping (Result<Data, Error>) -> ()) {
        
        components.path = "/getAudio"
        
        components.queryItems = parameters.map { key, value in
           return URLQueryItem(name: key, value: value)
        }
        
        if let url = components.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
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
                                completion(.success(data))
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
