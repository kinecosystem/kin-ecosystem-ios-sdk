import Foundation

/// common properties for all client events
struct Client: Codable {
    let carrier, deviceID, deviceManufacturer, deviceModel: String
    let language, os: String

    enum CodingKeys: String, CodingKey {
        case carrier
        case deviceID = "device_id"
        case deviceManufacturer = "device_manufacturer"
        case deviceModel = "device_model"
        case language, os
    }
}

public struct ClientProxy {
    var carrier: () -> (String)
    var deviceID: () -> (String)
    var deviceManufacturer: () -> (String)
    var deviceModel: () -> (String)
    var language: () -> (String)
    var os: () -> (String)
    var snapshot: Client {
        return Client(
            carrier: carrier(),
            deviceID: deviceID(),
            deviceManufacturer: deviceManufacturer(),
            deviceModel: deviceModel(),
            language: language(),
            os: os())
    }
}
