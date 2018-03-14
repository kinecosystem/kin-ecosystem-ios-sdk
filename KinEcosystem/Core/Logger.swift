//
//  Logger.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 12/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

enum LogLevel: String {
    case network = "NETWORK"
    case verbose = "VERBOSE"
    case info = "INFO"
    case warn = "WARNING"
    case error = "ERROR"
}

class Logger {
    fileprivate static let shared = Logger()
    var levels: [LogLevel] = [.info, .warn, .error]
    fileprivate func log(_ level: LogLevel, _ message: String, function: String, file: String, line: Int) {
        guard levels.isEmpty || levels.contains(level) else { return }
        let fileString = URL(string: file)?.deletingPathExtension().lastPathComponent
        print("\(level.rawValue) (\(fileString ?? "unknown file"): \(function), \(line)):", message)
    }
}

func logNetwork(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(.network, message, function: function, file: file, line: line)
}
func logVerbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(.verbose, message, function: function, file: file, line: line)
}
func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(.info, message, function: function, file: file, line: line)
}
func logWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(.warn, message, function: function, file: file, line: line)
}
func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(.error, message, function: function, file: file, line: line)
}
