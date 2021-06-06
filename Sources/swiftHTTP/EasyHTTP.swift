//
//  EasyHTTP.swift
//  swiftHTTP
//
//  Created by Hannes Harnisch on 02.12.20.
//

import Foundation
import Combine



class StandardHTTPRequest{
    static func with<T:Encodable>(url:String,body:T, methode:HttpMethode = .post) -> EasyHTTPRequest? {
        return EasyHTTPRequest(url: url, body: body, methode: methode)
    }
    static func with(url:String, methode:HttpMethode = .get) -> EasyHTTPRequest? {
        return EasyHTTPRequest(url: url, methode: methode)
    }
    static func ok<T:Encodable>(url:String,body:T, auth:String? = nil, methode:HttpMethode = .post) -> AnyPublisher<Bool,Never>{
        let easyHTTP = EasyHTTPRequest(url: url, body: body, methode: methode)
        if auth != nil{
            _ = easyHTTP!.setAuth(credentials: auth!)
        }
        return easyHTTP!.publisher(type: String.self).map { (string) -> Bool in
            return true
        }.replaceError(with: false).eraseToAnyPublisher()
    }
    static func ok(url:String,auth:String? = nil, methode:HttpMethode = .get)-> AnyPublisher<Bool,Never>{
        let easyHTTP = EasyHTTPRequest(url: url, methode: methode)
        if auth != nil{
            _ = easyHTTP.setAuth(credentials: auth!)
        }
        return easyHTTP.publisher(type: String.self).map { (string) -> Bool in
            return true
        }.replaceError(with: false).eraseToAnyPublisher()
    }
}

class EasyHTTPRequest{
    private var urlRequest:URLRequest
    init(url:String, methode:HttpMethode){
        if url.contains("://") {
            self.urlRequest = URLRequest(url: URL(string: url)!)
        }else{
            self.urlRequest = URLRequest(url: URL(string: "https://\(url)")!)
        }
        self.urlRequest.httpMethod = methode.rawValue
    }
    convenience init?<T:Encodable>(url:String,body:T, methode:HttpMethode){
        self.init(url:url, methode:methode)
        self.urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encoded = try? JSONEncoder().encode(body) else{
            return nil
        }
        self.urlRequest.httpBody = encoded
    }
    func setAuth(type:String = "Basic",credentials:String) -> EasyHTTPRequest {
        self.urlRequest.setValue("\(type) \(credentials)", forHTTPHeaderField: "Authorization")
        return self
    }
    func customHeaders(list:Dictionary<String,String>){
        for item in list{
            self.urlRequest.setValue(item.value, forHTTPHeaderField: item.key)
        }
    }
    func onDecodableResult<D:Decodable>(callback:@escaping (URLResponse?,Result<D,Error>)->Void) -> EasyHTTPSession{
        return EasyHTTPSession(urlRequest: self.urlRequest, callback: callback)
    }
    func onResult(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> EasyHTTPSession{
        return EasyHTTPSession(urlRequest: self.urlRequest, callback: callback)
    }
    func publisher<T:Decodable>(type:T.Type) -> AnyPublisher<T,Error>{
        return URLSession.shared.dataTaskPublisher(for: self.urlRequest).map{
            return $0.data
        }.decode(type: type, decoder: JSONDecoder()).eraseToAnyPublisher()
    }
}
class EasyHTTPSession {
    private var urlSession:URLSessionDataTask?
    private let urlRequest:URLRequest
    init<D:Decodable>(urlRequest:URLRequest, callback:@escaping (URLResponse?,Result<D,Error>)->Void){
        self.urlRequest = urlRequest
        self.urlSession = self.registerDataTask { (response, result) in
            switch result{
            case .success(let data):
                do{
                    let res = try JSONDecoder().decode(D.self, from: data)
                    callback(response,.success(res))
                }catch(let err){
                    callback(response,.failure(err))
                }
            case .failure(let err):
                callback(response,.failure(err))
            }
        }
    }
    init(urlRequest:URLRequest, callback:@escaping (URLResponse?,Result<Data,Error>) -> Void){
        self.urlRequest = urlRequest
        self.urlSession = self.registerDataTask(callback: callback)
    }
    func registerDataTask(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> URLSessionDataTask{
        return URLSession.shared.dataTask(with: self.urlRequest, completionHandler: { (data, response, error) in
            guard error == nil else{
                callback(response,.failure(error!))
                return
            }
            callback(response,.success(data!))
        })
    }
    func fire(){
        self.urlSession?.resume()
    }
}



enum HttpMethode:String{
    case put = "PUT"
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
    case create = "CREATE"
}
