import Foundation

/// common properties for all events
struct Common: Codable {
    let eventID: String
    let platform: String
    let timestamp, userID, version: String

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case platform, timestamp
        case userID = "user_id"
        case version
    }
}

public struct CommonProxy {
    var eventID: () -> (String)
    var platform: () -> (String) = { "iOS" }
    var timestamp: () -> (String)
    var userID: () -> (String)
    var version: () -> (String)
    var snapshot: Common {
        return Common(
            eventID: eventID(),
            platform: platform(),
            timestamp: timestamp(),
            userID: userID(),
            version: version())
    }
}
