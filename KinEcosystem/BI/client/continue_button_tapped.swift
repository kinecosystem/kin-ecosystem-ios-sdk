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

/// User click on "call to action" button on  page in new UI
struct ContinueButtonTapped: KBIEvent {
    let client: Client
    let common: Common
    let eventName: String
    let eventType: String
    let pageContinue: KBITypes.PageContinue
    let pageName: KBITypes.PageName
    let settingOption: KBITypes.SettingOption
    let user: User

    enum CodingKeys: String, CodingKey {
        case client, common
        case eventName = "event_name"
        case eventType = "event_type"
        case pageContinue = "page_continue"
        case pageName = "page_name"
        case settingOption = "setting_option"
        case user
    }
}







extension ContinueButtonTapped {
    init(pageContinue: KBITypes.PageContinue, pageName: KBITypes.PageName, settingOption: KBITypes.SettingOption) throws {
        let es = EventsStore.shared

        guard   let user = es.userProxy?.snapshot,
                let common = es.commonProxy?.snapshot,
                let client = es.clientProxy?.snapshot else {
                throw BIError.proxyNotSet
        }

        self.user = user
        self.common = common
        self.client = client

        eventName = "continue_button_tapped"
        eventType = "analytics"

        self.pageContinue = pageContinue
        self.pageName = pageName
        self.settingOption = settingOption
    }
}
