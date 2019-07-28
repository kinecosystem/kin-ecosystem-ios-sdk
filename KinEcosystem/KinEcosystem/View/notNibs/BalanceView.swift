//
//  BalanceView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/06/2019.
//

import KinMigrationModule

@available(iOS 9.0, *)
class BalanceView: UIView {
    let themeLinkBag = LinkBag()
    var theme: Theme?
    let label = UILabel(frame: .zero)
    var balanceObserver: String?

    var balance: Balance? {
        didSet {
            guard let theme = theme else { return }
            let amount = balance?.amount ?? 0
            label.attributedText = "\(amount)".styled(as: theme.titleViewBalance).kinPrefixed(with: Color.KinNewUi.bluishPurple)
            label.sizeToFit()
            invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addSubview(label)
        label.backgroundColor = .clear
        label.textAlignment = .left

        balanceObserver = Kin.shared.addBalanceObserver { [weak self] balance in
            DispatchQueue.main.async {
                self?.balance = balance
            }
        }

        setupTheming()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.center = boundsCenter
        label.centerY = label.centerY + 2
    }
    
    deinit {
        if let currentObserver = balanceObserver {
            Kin.shared.removeBalanceObserver(currentObserver)
        }
    }
}

extension BalanceView: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
      //  kinView.tintColor = theme.kinBalanceIconTint
        let dummy = balance
        balance = dummy
    }
}
