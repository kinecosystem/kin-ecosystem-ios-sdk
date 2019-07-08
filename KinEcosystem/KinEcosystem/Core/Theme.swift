//
//  Theme.swift
//  KinCoreSDK
//
//  Created by Elazar Yifrach on 19/05/2019.
//
import KinUtil

struct Theme {
    // text
    let title20: TextStyle
    let title18: TextStyle
    let subtitle14: TextStyle
    let subtitle12: TextStyle
    let title20Condensed: TextStyle
    let buttonTitle: TextStyle
    let titleViewBalance: TextStyle
    let spendTitle: TextStyle
    let offerDetails: TextStyle
    let earnTitle: TextStyle
    let balanceNotification: TextStyle
    let lightSubtitle14: TextStyle
    let historyRecentEarnAmount: TextStyle
    let balanceAmount: TextStyle
    let segmentSelectedTitle: TextStyle
    let segmentUnselectedTitle: TextStyle
    let historyAmount: TextStyle
    let historyRecentSpendAmount: TextStyle
    let settingsRowTitle: TextStyle
    let infoText: TextStyle
    let infoTitle: TextStyle
    
    // colors
    let viewControllerColor: UIColor
    let mainTintColor: UIColor
    
    let actionButtonEnabledColor: UIColor
    let actionButtonDisabledColor: UIColor
    let actionButtonHighlightedColor: UIColor
    
    let closeButtonTint: UIColor
    let dotsLoaderTint: UIColor
    let kinBalanceIconTint: UIColor
    
    let cellBorderColor: UIColor
    let settingsIconImageName: String
    let settingsIconBadgeImageName: String

    let textFieldIdle: UIColor
    let textFieldValid: UIColor
    let textFieldInvalid: UIColor

    let preferredStatusBarStyle: UIStatusBarStyle
}

extension Theme {
    static let light = Theme(title20: TextStyle.title20LightTheme,
                             title18: TextStyle.title18LightTheme,
                             subtitle14: TextStyle.subtitle14LightTheme,
                             subtitle12: TextStyle.subtitle12LightTheme,
                             title20Condensed: TextStyle.title20CondensedLightTheme,
                             buttonTitle: TextStyle.buttonTitleAnyTheme,
                             titleViewBalance: TextStyle.titleViewBalanceAnyTheme,
                             spendTitle: TextStyle.spendTitleAnyTheme,
                             offerDetails: TextStyle.offerDetailsLightTheme,
                             earnTitle: TextStyle.earnTitleAnyTheme,
                             balanceNotification: TextStyle.balanceNotificationLightTheme,
                             lightSubtitle14: TextStyle.lightSubtitle14AnyTheme,
                             historyRecentEarnAmount: TextStyle.historyRecentEarnAmountAnyTheme,
                             balanceAmount: TextStyle.balanceAmountAnyTheme,
                             segmentSelectedTitle: TextStyle.segmentSelectedTitleAnyTheme,
                             segmentUnselectedTitle: TextStyle.segmentUnselectedTitleAnyTheme,
                             historyAmount: TextStyle.historyAmountLightTheme,
                             historyRecentSpendAmount: TextStyle.historyRecentSpendAmountAnyTheme,
                             settingsRowTitle: TextStyle.settingsRowTitleLightTheme,
                             infoText: TextStyle.infoTextLightTheme,
                             infoTitle: TextStyle.infoTitleLightTheme,
                             viewControllerColor: Color.KinNewUi.white,
                             mainTintColor: Color.KinNewUi.black,
                             actionButtonEnabledColor: Color.KinNewUi.bluishPurple,
                             actionButtonDisabledColor: Color.KinNewUi.mercuryGray,
                             actionButtonHighlightedColor: Color.KinNewUi.bluishPurple.adjustBrightness(0.25),
                             closeButtonTint: Color.KinNewUi.brownGray,
                             dotsLoaderTint: Color.KinNewUi.bluishPurple,
                             kinBalanceIconTint: Color.KinNewUi.bluishPurple,
                             cellBorderColor: Color.KinNewUi.veryLightPink,
                             settingsIconImageName: "myKinIconLight",
                             settingsIconBadgeImageName: "myKinIconBadgeLight",
                             textFieldIdle: Color.KinNewUi.black,
                             textFieldValid: Color.KinNewUi.bluishPurple,
                             textFieldInvalid: Color.KinNewUi.darkishPink,
                             preferredStatusBarStyle: .default
                             )
    
}


class KinThemeProvider {
    static let shared = KinThemeProvider()
    var currentTheme = KinUtil.Observable<Theme>(.light).stateful()
}

protocol Themed {
    var themeLinkBag: LinkBag { get }
    func applyTheme(_ theme: Theme)
}

extension Themed where Self: AnyObject {
    func setupTheming() {
        if let theme = KinThemeProvider.shared.currentTheme.value {
            applyTheme(theme)
        }
        KinThemeProvider.shared.currentTheme.skip(1).on(queue: .main, next: { [weak self] theme in
            self?.applyTheme(theme)
        }).add(to: themeLinkBag)
    }
}
