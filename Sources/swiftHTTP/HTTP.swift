//
//  File.swift
//  
//
//  Created by Hannes Harnisch on 12.10.20.
//

import Foundation

/**
 Class for handling HTTP Requests
 */
public class EasyHTTP {
    private var urlRequest:URLRequest?
    private let methode:HttpMethode
    private var session:URLSessionDataTask?
    public init(methode:HttpMethode){
        self.methode = methode
    }
    public func with<T:Encodable>(url:String,body:T) -> EasyHTTP? {
        self.urlRequest = URLRequest(url: URL(string: url)!)
        self.urlRequest?.httpMethod = self.methode.rawValue
        switch self.methode {
        case .get:
            return self
        default:
            self.urlRequest!.setValue("application/json", forHTTPHeaderField: "Content-Type")
            guard let encoded = try? JSONEncoder().encode(body) else{
                return nil
            }
            self.urlRequest?.httpBody = encoded
            return self
        }
    }
    public func with(url:String) -> EasyHTTP? {
        self.urlRequest = URLRequest(url: URL(string: url)!)
        self.urlRequest?.httpMethod = self.methode.rawValue
        switch self.methode {
        case .get:
            return self
        default:
            return nil
        }
    }
    public func setAuth(type:String = "Basic",credentials:String) -> EasyHTTP {
        self.urlRequest!.setValue("\(type) \(credentials)", forHTTPHeaderField: "Authorization")
        return self
    }
    public func customHeaders(list:Dictionary<String,String>){
        for item in list{
            self.urlRequest!.setValue(item.key, forHTTPHeaderField: item.key)
        }
    }
    public func onResult(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> EasyHTTP{
        self.registerDataTask(callback: callback)
    }
    public func onResult<D:Decodable>(callback:@escaping (URLResponse?,Result<D,Error>)->Void) -> EasyHTTP{
        self.registerDataTask { (response, result) in
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
    private func registerDataTask(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> EasyHTTP{
        self.session = URLSession.shared.dataTask(with: self.urlRequest!, completionHandler: { (data, response, error) in
            guard error == nil else{
                callback(response,.failure(error!))
                return
            }
            callback(response,.success(data!))
        })
        return self
    }
    public func fire(){
        //print(urlRequest?.debugDescription)
        //print(urlRequest?.allHTTPHeaderFields)
        //print(String(data: (urlRequest?.httpBody) ?? "GET".data(using: .utf8)!, encoding: .utf8))
        self.session?.resume()
    }
}

public enum HttpMethode:String{
    case put = "PUT"
    case post = "POST"
    case get = "GET"
}
public struct EasyHTTPRequestSetup<L>{
    public let headers:Dictionary<String,String>?
    public let auth:String?
    public let authType:String
    private let dataprocessing:(URLResponse?,Result<Data,Error>) -> (L)
    
    public func build<T:Encodable>(url:String, body:T, methode:HttpMethode = .post,callback:@escaping (L) -> ()) -> EasyHTTP{
        let http = EasyHTTP(methode: methode).with(url: url, body: body)
        if self.auth != nil{
            http?.setAuth(type: authType, credentials: auth!)
        }
        http?.customHeaders(list: headers ?? Dictionary<String,String>())
        http?.onResult(callback: { (response, result) in
            callback(self.dataprocessing(response,result))
        })
        return http!
    }
    public func build(url:String,methode:HttpMethode = .get,callback:@escaping (L) -> ()) -> EasyHTTP{
        let http = EasyHTTP(methode: methode).with(url: url)
        if self.auth != nil{
            http?.setAuth(type: authType, credentials: auth!)
        }
        http?.customHeaders(list: headers ?? Dictionary<String,String>())
        http?.onResult(callback: { (response, result) in
            callback(self.dataprocessing(response,result))
        })
        return http!
    }
    public init(auth:String? = nil,authType:String = "Basic", headers:Dictionary<String,String>? = nil,dataprocessing:@escaping (URLResponse?,Result<Data,Error>) -> (L)){
        self.auth = auth
        self.authType = authType
        self.headers = headers
        self.dataprocessing = dataprocessing
    }
}
public struct EasyHTTPRequests {
    public static func ok(auth:String? = nil) -> EasyHTTPRequestSetup<Bool>{
        return EasyHTTPRequestSetup<Bool>(auth:auth) { (response, result) -> (Bool) in
            guard response != nil else{
                return false
            }
            guard let res = (response as? HTTPURLResponse) else{
                return false
            }
            return res.statusCode == 200
        }
    }
    public static func basic(auth:String? = nil) -> EasyHTTPRequestSetup<(URLResponse?,Result<Data,Error>)> {
        return EasyHTTPRequestSetup<(URLResponse?,Result<Data,Error>)>(auth: auth) { (response, res) -> ((URLResponse?,Result<Data,Error>)) in
            return (response,res)
        }
    }
    public static func standard<T:Decodable>(type:T.Type, auth:String? = nil)->EasyHTTPRequestSetup<(URLResponse?,Result<T,Error>)>{
        return EasyHTTPRequestSetup<(URLResponse?,Result<T,Error>)>(auth: auth) { (response, res) -> ((URLResponse?,Result<T,Error>)) in
            switch res{
            case .success(let data):
                do{
                    let resultObj = try JSONDecoder().decode(T.self, from: data)
                    return (response,.success(resultObj))
                }catch(let err){
                    return (response,.failure(err))
                }
            case .failure(let err):
                return (response,.failure(err))
            }
        }
    }
}
