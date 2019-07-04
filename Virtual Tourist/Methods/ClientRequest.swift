//
//  ClientRequest.swift
//  Virtual Tourist
//
//  Created by Tucker on 6/25/19.
//  Copyright © 2019 Tucker. All rights reserved.
//


import Foundation


func jsonDecoder<T : Codable>(data:Data,type:T.Type, completionHandler:@escaping (_ details: T) -> Void)throws  {
    let copyData = data
    let decoder = JSONDecoder()
    do {
        let jsonEncode = try decoder.decode(type, from:copyData)
        completionHandler(jsonEncode)
    } catch {
        throw CustomErrors.majorError
    }
}


public func get(url:URL,completionBlock:  @escaping  (Data?,URLResponse?,Error?)  -> Void)  -> Void {
    var request = URLRequest(url:url,timeoutInterval: 1.0)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let session = URLSession.shared
    let task = session.dataTask(with: request) {data,response,error in
        DispatchQueue.main.async  {
            completionBlock(data,response ,error)
        }
    }
    task.resume()
}





