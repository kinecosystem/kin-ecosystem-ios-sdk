import Foundation

struct KBITypes {
    enum PageName: String, Codable {
        case giftingDialog = "gifting_dialog"
    }
    enum ExitType: String, Codable {
        case backgroundApp = "background_app"
        case hostApp = "host_app"
        case xButton = "X_button"
    }
}
