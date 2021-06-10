//
//  EasyHTTP.swift
//  swiftHTTP
//
//  Created by Hannes Harnisch on 02.12.20.
//

import Foundation

public class EasyHTTPSession {
    private var urlSession:URLSessionDataTask?
    private let urlRequest:URLRequest
    init<D:Decodable>(urlRequest:URLRequest, session:URLSession, callback:@escaping (URLResponse?,Result<D,Error>)->Void){
        self.urlRequest = urlRequest
        self.urlSession = self.registerDataTask(session:session) { (response, result) in
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
    init(urlRequest:URLRequest, session:URLSession, callback:@escaping (URLResponse?,Result<Data,Error>) -> Void){
        self.urlRequest = urlRequest
        self.urlSession = self.registerDataTask(session: session, callback: callback)
    }
    func registerDataTask(session:URLSession,callback:@escaping (URLResponse?,Result<Data,Error>) -> Void) -> URLSessionDataTask{
        return session.dataTask(with: self.urlRequest, completionHandler: { (data, response, error) in
            guard error == nil else{
                callback(response,.failure(error!))
                return
            }
            callback(response,.success(data!))
        })
    }
    public func fire(){
        self.urlSession?.resume()
    }
}



public enum HttpMethode:String{
    case put = "PUT"
    case post = "POST"
    case get = "GET"
    case delete = "DELETE"
    case create = "CREATE"
}
