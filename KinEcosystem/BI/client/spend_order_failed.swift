// Please help improve quicktype by enabling anonymous telemetry with:
//
//   $ quicktype --telemetry enable
//
// You can also enable telemetry on any quicktype invocation:
//
//   $ quicktype pokedex.json -o Pokedex.cs --telemetry enable
//
// This helps us improve quicktype by measuring:
//
//   * How many people use quicktype
//   * Which features are popular or unpopular
//   * Performance
//   * Errors
//
// quicktype does not collect:
//
//   * Your filenames or input data
//   * Any personally identifiable information (PII)
//   * Anything not directly related to quicktype's usage
//
// If you don't want to help improve quicktype, you can dismiss this message with:
//
//   $ quicktype --telemetry disable
//
// For a full privacy policy, visit app.quicktype.io/privacy
//

import Foundation

/// Spend order fails
struct SpendOrderFailed: KBIEvent {
    let client: Client
    let common: Common
    let errorReason: String
    let eventName: String
    let eventType: String
    let isNative: Bool
    let offerID, orderID: String
    let origin: KBITypes.Origin
    let user: User

    enum CodingKeys: String, CodingKey {
        case client, common
        case errorReason = "error_reason"
        case eventName = "event_name"
        case eventType = "event_type"
        case isNative = "is_native"
        case offerID = "offer_id"
        case orderID = "order_id"
        case origin, user
    }
}



extension SpendOrderFailed {
    init(errorReason: String, isNative: Bool, offerID: String, orderID: String, origin: KBITypes.Origin) throws {
        let es = EventsStore.shared

        guard   let user = es.userProxy?.snapshot,
                let common = es.commonProxy?.snapshot,
                let client = es.clientProxy?.snapshot else {
                throw BIError.proxyNotSet
        }

        self.user = user
        self.common = common
        self.client = client

        eventName = "spend_order_failed"
        eventType = "log"

        self.errorReason = errorReason
        self.isNative = isNative
        self.offerID = offerID
        self.orderID = orderID
        self.origin = origin
    }
}
