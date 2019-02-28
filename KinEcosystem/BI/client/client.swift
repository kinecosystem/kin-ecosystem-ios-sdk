import Foundation

/// common properties for all client events
struct Client: Codable {
    let carrier, deviceManufacturer, deviceModel, language: String
    let os: String

    enum CodingKeys: String, CodingKey {
        case carrier
        case deviceManufacturer = "device_manufacturer"
        case deviceModel = "device_model"
        case language, os
    }
}

public struct ClientProxy {
    var carrier: () -> (String)
    var deviceManufacturer: () -> (String)
    var deviceModel: () -> (String)
    var language: () -> (String)
    var os: () -> (String)
    var snapshot: Client {
        return Client(
            carrier: carrier(),
            deviceManufacturer: deviceManufacturer(),
            deviceModel: deviceModel(),
            language: language(),
            os: os())
    }
}
