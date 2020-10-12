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
public class HTTP {
    private var urlRequest:URLRequest?
    private let methode:HttpMethode
    private var session:URLSessionDataTask?
    public init(methode:HttpMethode){
        self.methode = methode
    }
    public func with<T:Codable>(url:String,body:T? = nil) -> HTTP? {
        self.urlRequest = URLRequest(url: URL(string: url)!)
        self.urlRequest?.httpMethod = self.methode.rawValue
        switch self.methode {
        case .get:
            return self
        default:
            guard body != nil else {
                return nil
            }
            self.urlRequest!.setValue("application/json", forHTTPHeaderField: "Content-Type")
            guard let encoded = try? JSONEncoder().encode(body) else{
                return nil
            }
            self.urlRequest?.httpBody = encoded
            return self
        }
    }
    public func setAuth(type:String,credentials:String) -> HTTP {
        self.urlRequest!.setValue("\(type) \(credentials)", forHTTPHeaderField: "Authorization")
        return self
    }
    public func customHeaders(list:Dictionary<String,String>){
        for item in list{
            self.urlRequest!.setValue(item.key, forHTTPHeaderField: item.key)
        }
    }
    public func onResult(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> HTTP{
        self.registerDataTask(callback: callback)
    }
    public func onResult<D:Decodable>(callback:@escaping (URLResponse?,Result<D,Error>)->Void) -> HTTP{
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
    private func registerDataTask(callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> HTTP{
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
        self.session?.resume()
    }
}

public enum HttpMethode:String{
    case put = "PUT"
    case post = "POST"
    case get = "GET"
}
