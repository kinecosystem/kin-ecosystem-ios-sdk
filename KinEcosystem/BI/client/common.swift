import Foundation

/// common properties for all events
struct Common: Codable {
    let eventID: String
    let platform: String
    let schemaVersion, timestamp, userID, version: String

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case platform
        case schemaVersion = "schema_version"
        case timestamp
        case userID = "user_id"
        case version
    }
}

public struct CommonProxy {
    var eventID: () -> (String)
    var timestamp: () -> (String)
    var userID: () -> (String)
    var version: () -> (String)
    var snapshot: Common {
        return Common(
            eventID: eventID(),
            platform: "iOS",
            schemaVersion: "9a4f3c1f594bbfb6bc68008b21a83f31ab16ebe9",
            timestamp: timestamp(),
            userID: userID(),
            version: version())
    }
}
