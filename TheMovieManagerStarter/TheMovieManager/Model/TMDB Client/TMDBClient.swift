//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "2e5ecc55ec2f9aa77244bfccac8039d3"
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case getFavorites
        case search(String)
        case markWatchlist
        case markFavorite
        case posterImage(String)
        
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .posterImage(let posterPath): return "https://image.tmdb.org/t/p/w500" + posterPath
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                } catch {
                    do {
                        let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                        DispatchQueue.main.async {
                            completion(nil, errorResponse)
                        }
                        
                    }catch {
                        DispatchQueue.main.async {
                            completion(nil, error)
                        }
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    class func taskForPostRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType:  ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        request.httpBody = try! JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ResponseType.self, from: data)
//                Auth.requestToken = responseObject.request_token
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func logout(completionHandler: @escaping () -> Void) {
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LogoutRequest(sessionId: Auth.sessionId)
        request.httpBody = try! JSONEncoder().encode(body)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completionHandler()
        }
        task.resume()
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
//        var request = URLRequest(url: Endpoints.login.url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPostRequest(url: Endpoints.login.url, responseType: RequestTokenResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.requestToken = response.request_token
                completion(true, nil)
            }else {
                completion(false, nil)
            }
        }
    }
    
    class func CreateSessionId(completion: @escaping (Bool, Error?) -> Void) {
//        var request = URLRequest(url: Endpoints.createSessionId.url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = PostSession(requestToken: Auth.requestToken)
        taskForPostRequest(url: Endpoints.createSessionId.url, responseType: SessionResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
//                print("sessionIdIs \(Auth.sessionId)")
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
//        request.httpBody = try! JSONEncoder().encode(body)
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data else {
//                completion(false, error)
//                return
//            }
//            do {
//                let decoder = JSONDecoder()
//                let responseObject = try decoder.decode(SessionResponse.self, from: data)
//                Auth.sessionId = responseObject.sessionId
//                completion(true, nil)
//            }
//            catch {
//                completion(false, error)
//            }
//        }
//        task.resume()
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) -> URLSessionTask {
        
        let task = taskForGetRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.request_token
                completion(true, nil)
            }else {
                completion(false, error)
            }
        }
        return task
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
        let task = taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
        return task
    }
    
    class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
        let task = taskForGetRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
             if let response = response {
                completion(response.results, nil)
             }else {
                completion([], error)
            }
        }
        return task
    }
    
    class func search(query: String, completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
            let task = taskForGetRequest(url: Endpoints.search(query).url, response: MovieResults.self)  { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else {
                completion([], error)
            }
        }
        return task
    }
    
    class func markWatchlist(mediaId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkWatchlist(mediaType: "movie", mediaId: mediaId, watchlist: watchlist)
        taskForPostRequest(url: Endpoints.markWatchlist.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
//                print("statusCodeIs: \(response.statusCode)")
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil )
            }else {
                completion(false, error)
            }
        }
    }
    
    class func markFavorite(mediaId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkFavorite(mediaType: "movie", mediaId: mediaId, favorite: favorite)
        taskForPostRequest(url: Endpoints.markFavorite.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            }else {
                completion(false, error)
            }
        }
    }
    
    class func downloadPosterImage(path: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.posterImage(path).url) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
}
