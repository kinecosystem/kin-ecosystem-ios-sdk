//
//  PollingManager.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 31/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit

typealias PollingTaskCallback = (Error,Any) -> Void
class PollingTask: Equatable {
    private var cursor:Int?
    var task:URLSessionTask!
    var callback:PollingTaskCallback?
    var pattern:[Int]!
    convenience init(task:URLSessionTask, pattern:[Int]? = [1], _ callback:PollingTaskCallback? = nil) {
        self.init()
        self.task = task
        self.callback = callback
        self.pattern = pattern
    }
    static func ==(lhs: PollingTask, rhs: PollingTask) -> Bool {
        return lhs == rhs || lhs.task == rhs.task
    }
}
class PollingManager: NSObject {
    private static var pollingTasks = [PollingTask]()
    private static var timer:Timer?
    private static var isStarted:Bool { return timer != nil}
    public class func start() {
        if !isStarted {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
        }
    }
    public class func stop() {
        if isStarted {
            timer?.invalidate()
            timer = nil
        }
    }
    class public func add(task:PollingTask) {
        if !pollingTasks.contains(task) {
            pollingTasks.append(task)
            start()
        }
    }
    class public func remove(task:PollingTask) {
        if let index = pollingTasks.index(of:task) {
            task.task.cancel()
            pollingTasks.remove(at: index)
            if pollingTasks.count == 0 {
                stop()
            }
        }
    }
    @objc static private func handleTimer() {
        pollingTasks.forEach { poll in
            print("*",poll.task.state.rawValue)
            if poll.task.state != .running {//|| poll.task.state == .completed {
                //DispatchQueue.main.async {
                    poll.task.cancel()
                    poll.task.suspend()
                    poll.task.resume()
                   // }

            }
        }
    }
}
