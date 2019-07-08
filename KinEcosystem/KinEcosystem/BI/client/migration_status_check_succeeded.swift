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

/// Asking the server for account status - succeeded
struct MigrationStatusCheckSucceeded: KBIEvent {
    let blockchainVersion: KBITypes.BlockchainVersion
    let client: Client
    let common: Common
    let eventName: String
    let eventType: String
    let isRestorable: KBITypes.IsRestorable
    let publicAddress: String
    let shouldMigrate: KBITypes.IsRestorable
    let user: User

    enum CodingKeys: String, CodingKey {
        case blockchainVersion = "blockchain_version"
        case client, common
        case eventName = "event_name"
        case eventType = "event_type"
        case isRestorable = "is_restorable"
        case publicAddress = "public_address"
        case shouldMigrate = "should_migrate"
        case user
    }
}





extension MigrationStatusCheckSucceeded {
    init(blockchainVersion: KBITypes.BlockchainVersion, isRestorable: KBITypes.IsRestorable, publicAddress: String, shouldMigrate: KBITypes.IsRestorable) throws {
        let es = EventsStore.shared

        guard   let user = es.userProxy?.snapshot,
                let common = es.commonProxy?.snapshot,
                let client = es.clientProxy?.snapshot else {
                throw BIError.proxyNotSet
        }

        self.user = user
        self.common = common
        self.client = client

        eventName = "migration_status_check_succeeded"
        eventType = "log"

        self.blockchainVersion = blockchainVersion
        self.isRestorable = isRestorable
        self.publicAddress = publicAddress
        self.shouldMigrate = shouldMigrate
    }
}
