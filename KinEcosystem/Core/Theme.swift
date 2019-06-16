//
//  Theme.swift
//  KinCoreSDK
//
//  Created by Elazar Yifrach on 19/05/2019.
//
import KinUtil

struct Theme {
    // text
    var title20: TextStyle
    var title18: TextStyle
    var subtitle14: TextStyle
    var title20Condensed: TextStyle
    var buttonTitle: TextStyle
    var titleViewBalance: TextStyle
    var spendTitle: TextStyle
    var offerDetails: TextStyle
    var earnTitle: TextStyle
    var balanceNotification: TextStyle
    var lightSubtitle14: TextStyle
    var historyRecentEarnAmount: TextStyle
    var balanceAmount: TextStyle
    var segmentSelectedTitle: TextStyle
    var segmentUnselectedTitle: TextStyle
    var historyAmount: TextStyle
    var historyRecentSpendAmount: TextStyle
    var settingsRowTitle: TextStyle
    var infoText: TextStyle
    var infoTitle: TextStyle
    
    // colors
    var viewControllerColor: UIColor
    
    var purpleButtonEnabledColor: UIColor
    var purpleButtonDisabledColor: UIColor
    var purpleButtonHighlightedColor: UIColor
    var greenButtonEnabledColor: UIColor
    var greenButtonDisabledColor: UIColor
    var greenButtonHighlightedColor: UIColor
    
    var closeButtonTint: UIColor
    var dotsLoaderTint: UIColor
    var kinBalanceIconTint: UIColor
    
    var cellBorderColor: UIColor
    var settingsIconImageName: String
    var settingsIconBadgeImageName: String
}

extension Theme {
    
    static let light = Theme(title20: TextStyle.title20LightTheme,
                             title18: TextStyle.title18LightTheme,
                             subtitle14: TextStyle.subtitle14LightTheme,
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
                             viewControllerColor: .kinWhite,
                             purpleButtonEnabledColor: Color.KinNewUi.bluishPurple,
                             purpleButtonDisabledColor: Color.KinNewUi.bluishPurple.adjustBrightness(0.25).grayed(),
                             purpleButtonHighlightedColor: Color.KinNewUi.bluishPurple.adjustBrightness(0.25),
                             greenButtonEnabledColor: Color.KinNewUi.tealish,
                             greenButtonDisabledColor: Color.KinNewUi.tealish.adjustBrightness(0.25).grayed(),
                             greenButtonHighlightedColor: Color.KinNewUi.tealish.adjustBrightness(0.25),
                             closeButtonTint: Color.KinNewUi.brownGrey,
                             dotsLoaderTint: Color.KinNewUi.bluishPurple,
                             kinBalanceIconTint: Color.KinNewUi.bluishPurple,
                             cellBorderColor: Color.KinNewUi.veryLightPink,
                             settingsIconImageName: "myKinIconLight",
                             settingsIconBadgeImageName: "myKinIconBadgeLight"
        
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
