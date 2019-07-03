//
//  Iso8601DateFormatter.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

class Iso8601DateFormatter {
    
    static var formatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }
    
    static var relativeFormatter: DateFormatter {
        let shortFormatter = DateFormatter()
        shortFormatter.locale = Locale(identifier: "en_US_POSIX")
        shortFormatter.dateStyle = .short
        shortFormatter.timeStyle = .none
        shortFormatter.doesRelativeDateFormatting = true
        return shortFormatter
    }
    
    static func date(from string: String) -> Date? {
        let trimmedDate = string.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
        return formatter.date(from: trimmedDate)
    }
    
    static func string(from date: Date) -> String? {
        return formatter.string(from:date)
    }
    
    static func shortString(from date: Date) -> String? {
        return relativeFormatter.string(from: date)
    }
}
