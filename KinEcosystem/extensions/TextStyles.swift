#if os(OSX)
import AppKit.NSFont
internal typealias Font = NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit.UIFont
internal typealias Font = UIFont
#endif


enum TextStyle {
	case title20LightTheme
	case title18LightTheme
	case subtitle14LightTheme
	case title20CondensedLightTheme
	case buttonTitleAnyTheme
	case titleViewBalanceAnyTheme
	case spendTitleAnyTheme
	case offerDetailsLightTheme
	case earnTitleAnyTheme
	case title20DarkTheme
	case offerDetailsDarkTheme
	case balanceNotificationLightTheme
	case lightSubtitle14AnyTheme
	case historyRecentEarnAmountAnyTheme
	case balanceAmountAnyTheme
	case segmentSelectedTitleAnyTheme
	case segmentUnselectedTitleAnyTheme
	case historyAmountLightTheme
	case title18DarkTheme
	case balanceNotificationDarkTheme
	case historyAmountDarkTheme
	case historyRecentSpendAmountAnyTheme
	case settingsRowTitleLightTheme
	case settingsRowTitleDarkTheme
	case infoTextLightTheme
	case infoTitleLightTheme
	case title20CondensedDarkTheme
	case subtitle14DarkTheme
}

extension TextStyle {
	var attributes: [NSAttributedString.Key: Any] {
		switch self {
		case .title20LightTheme:
			return [.font: Font(name: "Sailec-Medium", size: 20) as Any,
				.foregroundColor: Color.KinNewUi.black]

		case .title18LightTheme:
			return [.font: Font(name: "Sailec-Medium", size: 18) as Any,
				.foregroundColor: Color.KinNewUi.black]

		case .subtitle14LightTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			paragraphStyle.minimumLineHeight = 20.83333333333334
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.black]

		case .title20CondensedLightTheme:
			return [.font: Font(name: "Sailec-Medium", size: 20) as Any,
				.foregroundColor: Color.KinNewUi.black,
				.kern: -0.7466666]

		case .buttonTitleAnyTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center

			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.white]

		case .titleViewBalanceAnyTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center

			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.bluishPurple,
				.kern: -0.4888889]

		case .spendTitleAnyTheme:
			return [.font: Font(name: "Sailec-Medium", size: 18) as Any,
				.foregroundColor: Color.KinNewUi.tealish]

		case .offerDetailsLightTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.minimumLineHeight = 18
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.black]

		case .earnTitleAnyTheme:
			return [.font: Font(name: "Sailec-Medium", size: 18) as Any,
				.foregroundColor: Color.KinNewUi.bluishPurple]

		case .title20DarkTheme:
			return [.font: Font(name: "Sailec-Medium", size: 20) as Any,
				.foregroundColor: Color.KinNewUi.white]

		case .offerDetailsDarkTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.minimumLineHeight = 18
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.whiteTwo]

		case .balanceNotificationLightTheme:
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.foregroundColor: Color.KinNewUi.black]

		case .lightSubtitle14AnyTheme:
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.foregroundColor: Color.KinNewUi.brownGrey]

		case .historyRecentEarnAmountAnyTheme:
			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.foregroundColor: Color.KinNewUi.bluishPurple]

		case .balanceAmountAnyTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .right

			return [.font: Font(name: "Sailec-Medium", size: 24) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.bluishPurple,
				.kern: -0.5466666]

		case .segmentSelectedTitleAnyTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center

			return [.font: Font(name: "Sailec-Medium", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.white,
				.kern: -0.08615384]

		case .segmentUnselectedTitleAnyTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center

			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color(red: 140/255.0, green: 140/255.0, blue: 140/255.0, alpha: 1),
				.kern: -0.08615384]

		case .historyAmountLightTheme:
			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.foregroundColor: Color.KinNewUi.black]

		case .title18DarkTheme:
			return [.font: Font(name: "Sailec-Medium", size: 18) as Any,
				.foregroundColor: Color.KinNewUi.whiteTwo]

		case .balanceNotificationDarkTheme:
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.foregroundColor: Color.KinNewUi.whiteTwo]

		case .historyAmountDarkTheme:
			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.foregroundColor: Color.KinNewUi.whiteTwo]

		case .historyRecentSpendAmountAnyTheme:
			return [.font: Font(name: "Sailec-Medium", size: 16) as Any,
				.foregroundColor: Color.KinNewUi.tealish]

		case .settingsRowTitleLightTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.minimumLineHeight = 22
			return [.font: Font(name: "Sailec-Medium", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.black,
				.kern: -0.3376471]

		case .settingsRowTitleDarkTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.minimumLineHeight = 22
			return [.font: Font(name: "Sailec-Medium", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.whiteTwo,
				.kern: -0.3376471]

		case .infoTextLightTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			paragraphStyle.minimumLineHeight = 22
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.black,
				.kern: -0.3188889]

		case .infoTitleLightTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center

			return [.font: Font(name: "Sailec-Regular", size: 20) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.black]

		case .title20CondensedDarkTheme:
			return [.font: Font(name: "Sailec-Medium", size: 20) as Any,
				.foregroundColor: Color.KinNewUi.whiteTwo,
				.kern: -0.7466666]

		case .subtitle14DarkTheme:
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			paragraphStyle.minimumLineHeight = 20.83333333333334
			return [.font: Font(name: "Sailec-Regular", size: 14) as Any,
				.paragraphStyle: paragraphStyle,
				.foregroundColor: Color.KinNewUi.whiteTwo]

		}
	}


}

extension String {
  func styled(as style: TextStyle) -> NSAttributedString {
    return NSAttributedString(string: self,
                              attributes: style.attributes)
  }
}
