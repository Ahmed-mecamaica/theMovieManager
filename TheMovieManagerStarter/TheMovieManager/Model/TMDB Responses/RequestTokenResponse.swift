//
//  RequestTokenResponse.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

struct RequestTokenResponse: Codable {
    let success: Bool
    let expires_at: String
    let request_token: String
    
//    enum codingKey: String, CodingKey {
//        case success
//        case expiredAt = "expires_at"
//        case requestToken = "request_token"
//    }
}


