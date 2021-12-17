//
//  EasyHTTPRequest.swift
//  
//
//  Created by Hannes Harnisch on 10.06.21.
//

import Foundation
import Combine

public class EasyHTTPRequest{
    private var urlRequest:URLRequest
    private var urlSession:URLSession = URLSession.shared
    public init(url:String, methode:HttpMethode){
        if url.contains("://") {
            self.urlRequest = URLRequest(url: URL(string: url)!)
        }else{
            self.urlRequest = URLRequest(url: URL(string: "https://\(url)")!)
        }
        self.urlRequest.httpMethod = methode.rawValue
    }
    public convenience init?<T:Encodable>(url:String,body:T, methode:HttpMethode){
        self.init(url:url, methode:methode)
        self.urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let encoded = try? JSONEncoder().encode(body) else{
            return nil
        }
        self.urlRequest.httpBody = encoded
    }
    public func setAuth(type:String = "Basic",credentials:String) -> EasyHTTPRequest {
        self.urlRequest.setValue("\(type) \(credentials)", forHTTPHeaderField: "Authorization")
        return self
    }
    public func ignoreCertificate() -> EasyHTTPRequest {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        self.urlSession = URLSession(configuration: config, delegate: IgnoreCertSessionDelegate(), delegateQueue: OperationQueue())
        return self
    }
    public func urlSessionDelegate(delegate:URLSessionDelegate) -> EasyHTTPRequest {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        self.urlSession = URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue())
        return self
    }
    public func customHeaders(list:Dictionary<String,String>) -> EasyHTTPRequest {
        for item in list{
            self.urlRequest.setValue(item.value, forHTTPHeaderField: item.key)
        }
        return self
    }
    public func onDecodableResult<D:Decodable>(callback:@escaping (URLResponse?,Result<D,Error>)->Void) -> EasyHTTPSession{
        return EasyHTTPSession(urlRequest: self.urlRequest,session: self.urlSession, callback: callback)
    }
    public func onResult(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> EasyHTTPSession{
        return EasyHTTPSession(urlRequest: self.urlRequest,session: self.urlSession, callback: callback)
    }
    public func publisher() -> URLSession.DataTaskPublisher {
        return self.urlSession.dataTaskPublisher(for: self.urlRequest)
    }
    public func publisher<T:Decodable>(_ type:T.Type) -> AnyPublisher<T,Error>{
        return self.urlSession.dataTaskPublisher(for: self.urlRequest).tryMap() { element -> Data in
            guard let httpResponse = element.response as? HTTPURLResponse else{
                throw URLError(.badServerResponse)
            }
            guard httpResponse.statusCode == 200 else {
                    switch httpResponse.statusCode {
                    case 400:
                        throw URLError(.unknown)
                    case 401:
                        throw URLError(.userAuthenticationRequired)
                    default:
                        throw URLError(.badServerResponse)
                    }
            }
            return element.data
        }.decode(type: type, decoder: JSONDecoder()).eraseToAnyPublisher()
    }
    @available(watchOS 8.0, *)
    @available(tvOS 15.0, *)
    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public func data(delegate:URLSessionTaskDelegate? = nil) async throws -> (Data,HTTPURLResponse) {
        let (data,response) = try await self.urlSession.data(for: self.urlRequest,delegate: delegate)
        guard let res = response as? HTTPURLResponse else{
            throw URLError(.unknown)
        }
        return (data,res)
    }
    
    @available(watchOS 8.0, *)
    @available(tvOS 15.0, *)
    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public func data<T:Decodable>(_ type:T.Type,delegate:URLSessionTaskDelegate? = nil)  async throws -> T {
        let (data,response) = try await self.urlSession.data(for: self.urlRequest,delegate: delegate)
        guard let res = response as? HTTPURLResponse else{
            throw URLError(.unknown)
        }
        guard res.statusCode == 200 else {
            switch res.statusCode {
            case 400:
                throw URLError(.unknown)
            case 401:
                throw URLError(.userAuthenticationRequired)
            default:
                throw URLError(.badServerResponse)
            }
        }
        return try JSONDecoder().decode(type, from: data)
    }
}
private class IgnoreCertSessionDelegate:NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential,URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
