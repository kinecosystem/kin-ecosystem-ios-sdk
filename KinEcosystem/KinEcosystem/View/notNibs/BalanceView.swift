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
    let kinView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 8.0, height: 8.0))
    //let stackView: UIStackView
    
    var balanceObserver: String?
    var balance: Balance? {
        didSet {
            updateBalanceLabel()
        }
    }
    override init(frame: CGRect) {
       // stackView = UIStackView(arrangedSubviews: [kinView, label])
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
       // stackView = UIStackView(arrangedSubviews: [kinView, label])
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit() {
        addSubview(label)
        addSubview(kinView)
       
        label.backgroundColor = .clear
        label.textAlignment = .left
        kinView.backgroundColor = .clear
      
        kinView.image = UIImage(named: "balanceKinIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        kinView.contentMode = .scaleAspectFit
        kinView.transform = CGAffineTransform(translationX: 0, y: -2)
        balanceObserver = Kin.shared.addBalanceObserver { [weak self] balance in
            DispatchQueue.main.async {
                self?.balance = balance
            }
        }
//        stackView.alignment = .center
//        stackView.axis = .horizontal
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.spacing = 3
//
//        addSubview(stackView)
//        NSLayoutConstraint.activate([
//            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
//            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
//            topAnchor.constraint(equalTo: stackView.topAnchor),
//            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
//            ])
        setupTheming()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.center = boundsCenter
        kinView.center = boundsCenter
        kinView.x = label.x - kinView.frame.width - 2
    }
    func updateBalanceLabel() {
        guard let theme = theme else { return }
        let amount = balance?.amount ?? 0
        label.attributedText = "\(amount)".styled(as: theme.titleViewBalance)
        label.sizeToFit()
        invalidateIntrinsicContentSize()
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
        kinView.tintColor = theme.kinBalanceIconTint
        updateBalanceLabel()
    }
}
