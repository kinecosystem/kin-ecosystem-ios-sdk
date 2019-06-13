//
//  BalanceView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/06/2019.
//

import KinMigrationModule

class BalanceView: UIView {
    
    let themeLinkBag = LinkBag()
    var theme: Theme?
    let label = UILabel(frame: .zero)
    let kinView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 8.0, height: 8.0))
    var balanceObserver: String?
    var balance: Balance? {
        didSet {
            updateBalanceLabel()
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
        label.backgroundColor = .clear
        label.textAlignment = .left
        kinView.backgroundColor = .clear
        backgroundColor = .clear
        kinView.image = UIImage(named: "balanceKinIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        kinView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        balanceObserver = Kin.shared.addBalanceObserver { [weak self] balance in
            DispatchQueue.main.async {
                self?.balance = balance
            }
        }
        addSubview(label)
        addSubview(kinView)
        setupTheming()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.sizeToFit()
        kinView.center = CGPoint(x: 7.0, y: label.bounds.height / 2.0)
        label.frame = CGRect(x: 14.0, y: 0.0, width: label.bounds.width, height: frame.height)
        self.bounds = CGRect(x: 0.0, y: 0.0, width: 17.0 + label.bounds.width, height: frame.height)
    }
    
    func updateBalanceLabel() {
        guard let theme = theme else { return }
        let amount = balance?.amount ?? 0
        label.attributedText = "\(amount)".styled(as: theme.titleViewBalance)
        setNeedsLayout()
    }
    
    deinit {
        guard let currentObserver = balanceObserver else {
            return
        }
        Kin.shared.removeBalanceObserver(currentObserver)
    }
    
}


extension BalanceView: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        kinView.tintColor = theme.kinBalanceIconTint
        updateBalanceLabel()
    }
}
