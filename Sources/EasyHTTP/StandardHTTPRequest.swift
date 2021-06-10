//
//  StandardHTTPRequest.swift
//  
//
//  Created by Hannes Harnisch on 10.06.21.
//

import Foundation
import Combine

public class StandardHTTPRequest{
    public static func with<T:Encodable>(url:String,body:T, methode:HttpMethode = .post) -> EasyHTTPRequest? {
        return EasyHTTPRequest(url: url, body: body, methode: methode)
    }
    public static func with(url:String, methode:HttpMethode = .get) -> EasyHTTPRequest? {
        return EasyHTTPRequest(url: url, methode: methode)
    }
    public static func ok<T:Encodable>(url:String,body:T, auth:String? = nil, methode:HttpMethode = .post) -> AnyPublisher<Bool,Never>{
        let easyHTTP = EasyHTTPRequest(url: url, body: body, methode: methode)
        if auth != nil{
            _ = easyHTTP!.setAuth(credentials: auth!)
        }
        return easyHTTP!.publisher(type: String.self).map { (string) -> Bool in
            return true
        }.replaceError(with: false).eraseToAnyPublisher()
    }
    public static func ok(url:String,auth:String? = nil, methode:HttpMethode = .get)-> AnyPublisher<Bool,Never>{
        let easyHTTP = EasyHTTPRequest(url: url, methode: methode)
        if auth != nil{
            _ = easyHTTP.setAuth(credentials: auth!)
        }
        return easyHTTP.publisher(type: String.self).map { (string) -> Bool in
            return true
        }.replaceError(with: false).eraseToAnyPublisher()
    }
}
