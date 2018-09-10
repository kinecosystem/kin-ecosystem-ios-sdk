//
//  BIClient.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 27/06/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreTelephony

class BIClient {
    
    let endpoint: URL
    let encoder = JSONEncoder()
    let sendQueue: OperationQueue
    let fm = FileManager.default
    let logboxURL: URL
    let reachability: Reachability
    let networkInfo = CTTelephonyNetworkInfo()
    
    init(endpoint: URL) throws {
        self.endpoint = endpoint
        guard   let host = endpoint.host,
                let reach = Reachability(hostname: host) else {
            throw BIError.setup
        }
        reachability = reach
        sendQueue = OperationQueue()
        sendQueue.isSuspended = true
        sendQueue.maxConcurrentOperationCount = 4
        logboxURL = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("kin_es_events_logbox")
        try FileManager.default.createDirectory(at: logboxURL, withIntermediateDirectories: true, attributes: nil)
        reachability.whenReachable = { [weak self] reachability in
            self?.sendQueue.isSuspended = false
        }
        reachability.whenUnreachable = { [weak self] _ in
            self?.sendQueue.isSuspended = true
        }
        try reachability.startNotifier()
        // TODO: pickup leftover files and wrap them
    }
    
    func send<T: KBIEvent>(_ event: T) throws {
        let data = try encoder.encode(event)
        let url = logboxURL.appendingPathComponent("\(event.common.eventID).json")
        logVerbose("bi: \(event.eventName)")

        try data.write(to: url, options: .atomic)
        wrap(data, at: url, eventId: event.common.eventID)
    }
    
    func wrap(_ data: Data, at url: URL, eventId: String) {
        
        var request = URLRequest(url: endpoint)
        request.httpBody = data
        
        request.httpMethod = HTTPMethod.post.rawValue
        
        request.addValue(ContentType.json.rawValue, forHTTPHeaderField: "Accept")
        request.addValue(ContentType.json.rawValue, forHTTPHeaderField: "content-type")
        request.addValue(eventId, forHTTPHeaderField: "X-REQUEST-ID")
        
        request.allowsCellularAccess = true
        
        let operation = BlockOperation { [weak self] in
            guard let this = self else { return }
            let group = DispatchGroup()
            group.enter()
            var success = true
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                defer {
                    group.leave()
                }
                guard   let httpResponse = response as? HTTPURLResponse,
                    200 ... 299 ~= httpResponse.statusCode else {
                    success = false
                    logError("failed to send event")
                    return
                }
            }.resume()
            group.wait()
            if success {
                do {
                    try this.fm.removeItem(at: url)
                } catch {
                    logError("failed to remove event file")
                }
            }
        }
        
        sendQueue.addOperation(operation)
    }
}
