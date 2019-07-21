//
//  BalanceView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/06/2019.
//

import KinMigrationModule


extension UIView {
    var x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set (value){
            self.frame=CGRect(x: value, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }
    }

    var y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set(value) {
            self.frame=CGRect(x: self.frame.origin.x, y: value, width: self.frame.size.width, height: self.frame.size.height)
        }
    }

    var width: CGFloat {
        get {
            return self.frame.size.width
        }
        set (value){
            self.frame=CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: value, height: self.frame.size.height)
        }
    }

    var height: CGFloat {
        get { return frame.size.height }
        set(value) { frame=CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height:value)}
    }
}
@available(iOS 9.0, *)
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
        setupTheming()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.center = CGPoint(x:self.bounds.midX,y:self.bounds.midY)
        label.x = label.x + kinView.width / 2.0
        kinView.center = CGPoint(x:self.bounds.midX,y:self.bounds.midY)
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
