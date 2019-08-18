 //
//  ActionFactory.swift
//  HereSwift
//
//  Created by Alon Genosar on 7/19/17.
//  Copyright © 2017 Alon Genosar. All rights reserved.
//

import UIKit
//extension String: Error {}
typealias EncoderBlock = ((inout URLRequest,Dictionary<String,Any>?) throws -> Void)?
typealias ParserBlock = ((Data?) throws -> Any?)?
typealias CallbackBlock = ((NSError?, Any?) -> Void)?
protocol SessionTaskParser {
    
    func parse(data:NSData, callback:Any)
    
}

class URLTaskFactory: NSObject {

   
    //
    // REQUEST FACTORY
    //
    class func taskWith(url: String, session: URLSession = URLSession.shared, encoder: EncoderBlock, parser: ParserBlock, data: (Dictionary<String,AnyObject>?),cashBust: Bool = false, callback: CallbackBlock) -> URLSessionDataTask{
        return self.taskWith(request: URLRequest(url:URL(string:url)!), session: session, encoder: encoder, parser: parser, data: data,cacheBust:cashBust, callback: callback)
    }
    //
    // TASK FACTORY
    //
    class func taskWith(request: URLRequest, session: URLSession = URLSession.shared , encoder: EncoderBlock, parser: ParserBlock, data: (Dictionary<String,Any>?),cacheBust: Bool = false, callback: CallbackBlock) -> URLSessionDataTask{
        
        var request=request;
       
        var resultError: NSError?
        var result : Any?
    
        if let encoder=encoder {
            do { try encoder(&request, data);}
            catch {}
        }
        if(cacheBust) {
            do { try uriEncoder(request: &request,data:["cashBust": String(arc4random())]);}
            catch {}
        }
        let task : URLSessionDataTask = session.dataTask(with: request, completionHandler:{(data,response,error) in
            
            guard let response=response else {
               
                if let callback=callback {
                    callback(NSError(domain: "Unknown error", code: 500, userInfo: nil),nil)
                    
                }
                return;
            }
            let statusCode:NSInteger=(response as! HTTPURLResponse).statusCode
            
            if let error: Error = error {
                resultError=NSError(domain: error.localizedDescription, code: statusCode, userInfo: nil)
            }
            else if(statusCode>299) {
                resultError=NSError(domain:"Error", code: statusCode, userInfo: nil)
            }
            if let parser=parser {
                
                do {
                    result=try parser(data);
                }
                catch {
                    
                }
            }
            else {
                result=data;
            }
            if let callback=callback {
                DispatchQueue.main.async {
                    callback(resultError,result)
                }
            }
           
    })

    return task;
}
    
    //
    // E N C O D E R S
    //
    class func jsonBodyEncoder(request:inout URLRequest,data:Dictionary<String,Any>?) throws -> Void {
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        request.addValue("application/json", forHTTPHeaderField: "Accept");
        request.httpMethod="POST"
       
        //do {
        if let data=data {
            
            let json:Data=try JSONSerialization.data(withJSONObject: data, options:[])
            request.addValue(String(json.count), forHTTPHeaderField: "Content-Length");
            request.httpBody=json;
        }
       // }
       // catch {
            
            
       // }
    }
  
    class func uriEncoder(request:inout URLRequest,data:Dictionary<String,Any>?) throws -> Void {
        
        request.httpMethod="GET"
        var components: URLComponents=URLComponents(string: (request.url?.absoluteString)!)!
        var queryItems: Array<URLQueryItem>=components.queryItems ?? Array()
       
         if let data=data  {
            for (key, value) in data {
                queryItems.append(URLQueryItem(name: key as String, value:  String(describing: value)))
            }
        }
        components.queryItems=queryItems
        request.url=components.url
        }
    
    //
    // PARSERS
    //
    class func jsonBodyParser(data: Data?) throws ->Any? {
        
        if let data=data {
        
            do {
                return try JSONSerialization.jsonObject(with: data)
            }
            catch {
                throw error
            }
        }
        else  {
            
            return nil;
           // throw "data isn't json"
        }
        
   }
//    class func ImageParser(data: Data) -> (NSError?,Dictionary<String,Any>?) {
//        if let data = data {
//            return UIImage(data:data)
//        }
//        else {
//            return nil
//        }
//    }
}

