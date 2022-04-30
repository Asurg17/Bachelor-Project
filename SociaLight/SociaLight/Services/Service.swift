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
        components.scheme = "https"
        components.host = "alocalhost:8080"
    }
    
    func registerNewUser(completion: @escaping (Result<String, Error>) -> ()) {
        components.path = "/registerClient"
    }
    
    
    
}
