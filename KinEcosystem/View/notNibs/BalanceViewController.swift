//
//  BalanceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinCoreSDK
import KinUtil
import StellarKit
import CoreDataStack

@available(iOS 9.0, *)
class BalanceViewController: KinViewController {

    var core: Core!
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var balance: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var rightAmountConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightArrowImage: UIImageView!

    fileprivate var selected = false
    fileprivate let bag = LinkBag()
    fileprivate var watchedOrderStatus: OrderStatus?

    fileprivate var entityWatcher: EntityWatcher<Order>?
    fileprivate var currentOrderId: String?
    var watchedOrderId: String? {
        get {
            return currentOrderId
        }
        set {
            guard newValue != currentOrderId else { return }
            currentOrderId = newValue
            entityWatcher = nil
            guard let orderId = currentOrderId else { return }
            setupOrderWatcherFor(orderId)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        core.blockchain.balanceObservable.on(queue: .main, next: { [weak self] balance in
            guard let this = self else { return }

            this.balanceAmount.attributedText = "\(balance.amount.currencyString())".attributed(24.0, weight: .regular,
                                                                                        color: .kinDeepSkyBlue)


        }).add(to: bag)
        _ = core.blockchain.balance()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "WatchOrderNotification"), object: nil, queue: .main) { [weak self] note in
            guard let orderId = note.object as? String else {

                guard let status = self?.watchedOrderStatus, status != .pending else {
                    return
                }
                guard let label = self?.subtitle else { return }
                self?.switchLabel(label, text: "Welcome to Kin Marketplace".attributed(14.0, weight: .regular, color: .kinBlueGreyTwo))
                self?.watchedOrderId = nil
                self?.watchedOrderStatus = nil
                return
            }
            self?.watchedOrderId = orderId
        }
    }



    func setSelected(_ selected: Bool, animated: Bool) {
        guard self.selected != selected else { return }

        self.selected = selected

        self.rightAmountConstraint.constant = selected ? 0.0 : 20.0
        let block = {
            self.rightArrowImage.alpha = selected ? 0.0 : 1.0
            self.view.layoutIfNeeded()
        }

        guard animated else {
            block()
            return
        }

        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            block()
        }
    }

    func switchLabel(_ label: UILabel, text: NSAttributedString) {
        if let string = label.attributedText?.string {
            guard string != text.string else { return }
        }
        label.layer.transform = CATransform3DIdentity
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState], animations: {
            label.layer.transform = CATransform3DRotate(label.layer.transform, CGFloat.pi / 2.0, 1.0, 0.0, 0.0)
        }) { finished in
            label.attributedText = text
            UIView.animate(withDuration: 0.04, delay: 0.1, options: [.beginFromCurrentState], animations: {
                label.layer.transform = CATransform3DIdentity
            })
        }
    }

    func setupOrderWatcherFor(_ orderId: String) {
        if let watcher = try? EntityWatcher<Order>(predicate: NSPredicate(with: ["id":orderId]), sortDescriptors: [], context: core.data.stack.viewContext) {
            entityWatcher = watcher
            entityWatcher?.on(EntityWatcher<Order>.Event.change, handler: { [weak self] change in
                guard let order = change?.entity else {
                    logWarn("Entity watcher inconsistent")
                    return
                }
                let status = order.orderStatus
                let spend = order.offerType == .spend
                let amount = order.amount
                self?.watchedOrderStatus = order.orderStatus
                DispatchQueue.main.async {
                    guard let label = self?.subtitle else { return }
                    switch status {
                    case .completed:
                        self?.switchLabel(label, text: (spend ? "Great, your code is ready" : "Done! \(amount) Kin earned").attributed(14.0, weight: .regular, color: .kinDeepSkyBlue))
                    case .pending:
                        self?.switchLabel(label, text: (spend ? "Thanks! We're generating your code..." : "Thanks! \(amount) Kin are on the way").attributed(14.0, weight: .regular, color: .kinBlueGreyTwo))
                    case .failed:
                        self?.switchLabel(label, text: "Oops - something went wrong".attributed(14.0, weight: .regular, color: .kinCoralPink))
                    case .delayed:
                        self?.switchLabel(label, text: "Sorry - this may take some time".attributed(14.0, weight: .regular, color: .kinMango))
                    }
                }
            })
        }
    }

}
