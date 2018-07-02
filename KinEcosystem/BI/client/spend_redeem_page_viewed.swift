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

/// User views the redeem code page. Source is either "spend flow" or "transaction history"
/// page
struct SpendRedeemPageViewed: KBIEvent {
    let client: Client
    let common: Common
    let eventName: String
    let eventType: String
    let kinAmount: Double
    let offerID, orderID: String
    let redeemTrigger: KBITypes.RedeemTrigger
    let user: User

    enum CodingKeys: String, CodingKey {
        case client, common
        case eventName = "event_name"
        case eventType = "event_type"
        case kinAmount = "kin_amount"
        case offerID = "offer_id"
        case orderID = "order_id"
        case redeemTrigger = "redeem_trigger"
        case user
    }
}



extension SpendRedeemPageViewed {
    init(kinAmount: Double, offerID: String, orderID: String, redeemTrigger: KBITypes.RedeemTrigger) throws {
        let es = EventsStore.shared

        guard   let user = es.userProxy?.snapshot,
                let common = es.commonProxy?.snapshot,
                let client = es.clientProxy?.snapshot else {
                throw BIError.proxyNotSet
        }

        self.user = user
        self.common = common
        self.client = client

        eventName = "spend_redeem_page_viewed"
        eventType = "analytics"

        self.kinAmount = kinAmount
        self.offerID = offerID
        self.orderID = orderID
        self.redeemTrigger = redeemTrigger
    }
}
