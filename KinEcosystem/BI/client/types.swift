import Foundation

struct KBITypes {
    enum OfferType: String, Codable {
        case coupon = "coupon"
        case external = "external"
        case poll = "poll"
        case quiz = "quiz"
        case tutorial = "tutorial"
    }
    enum Origin: String, Codable {
        case external = "external"
        case marketplace = "marketplace"
    }
    enum RedeemTrigger: String, Codable {
        case systemInit = "system_init"
        case userInit = "user_init"
    }
}
