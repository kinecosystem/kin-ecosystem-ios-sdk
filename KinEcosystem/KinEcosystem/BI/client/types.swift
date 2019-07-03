import Foundation

struct KBITypes {
    enum PageName: String, Codable {
        case dialogsNotEnoughKin = "dialogs_not_enough_kin"
        case dialogsSpendConfirmationScreen = "dialogs_spend_confirmation_screen"
        case mainPage = "main_page"
        case myKinPage = "my_kin_page"
        case onboarding = "onboarding"
        case settings = "settings "
    }
    enum PageContinue: String, Codable {
        case mainPageContinueToMyKin = "main_page_continue_to_my_kin"
        case myKinPageContinueToSettings = "my_kin_page_continue_to_settings"
        case notEnoughKinContinueButton = "not_enough_kin_continue_button"
        case onboardingContinueToMainPage = "onboarding_continue_to_main_page"
        case settingsPageContinueToOptions = "settings_page_continue_to_options"
        case spendConfirmationContinueButton = "spend_confirmation_continue_button"
    }
    enum SettingOption: String, Codable {
        case backup = "backup"
        case restore = "restore"
    }
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
    enum ExitType: String, Codable {
        case androidNavigator = "Android_navigator"
        case backgroundApp = "background_app"
        case xButton = "X_button"
    }
    enum BlockchainVersion: String, Codable {
        case the2 = "2"
        case the3 = "3"
    }
    enum IsRestorable: String, Codable {
        case no = "no"
        case yes = "yes"
    }
    enum MessageType: String, Codable {
        case earnConfirmation = "earn_confirmation "
        case error = "error "
        case genericNative = "generic_native "
        case noWallet = "no_wallet "
        case spendConfirmation = "spend_confirmation"
        case whatIsKin = "what_is_kin"
    }
    enum RedeemTrigger: String, Codable {
        case systemInit = "system_init"
        case userInit = "user_init"
    }
}
