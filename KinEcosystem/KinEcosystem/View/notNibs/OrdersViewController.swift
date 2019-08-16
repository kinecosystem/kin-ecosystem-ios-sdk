//
//  OrdersViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule
import CoreData
import CoreDataStack

protocol OrdersViewControllerDelegate: class {
    func ordersViewControllerDidTapSettings()
}

@available(iOS 9.0, *)
class OrdersViewController: UIViewController {
    var core: Core!
    weak var delegate: OrdersViewControllerDelegate?

    fileprivate let orderCellName = "OrderCell"
    fileprivate(set) var orderViewModels = [String : OrderViewModel]()
    let themeLinkBag = LinkBag()
    fileprivate var theme: Theme?
    @IBOutlet weak var segmentedControl: KinSegmentedControl!
    @IBOutlet weak var tableView: UITableView!
   // @IBOutlet weak var balanceContainer: UIView!
    fileprivate var offerType: OfferType = .earn {
        didSet {
            setupFRCSections()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BalanceViewController {
            vc.core = core
        }
    }
//    convenience init(core: Core) {
//        self.init(nibName: "OrdersViewController", bundle: KinBundle.ecosystem.rawValue)
//        self.core = core
//        loadViewIfNeeded()
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupExtraViews()
        setupTheming()
        setupTableView()
        setupFRCSections()
        Kin.track { try OrderHistoryPageViewed() }
        Theme.light
        
        let backImage = Theme.navigationBarBackButton
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        navigationItem.backBarButtonItem?.title = ""
        navigationController?.navigationBar.topItem?.title = ""
        
        segmentedControl.leftItem = "kinecosystem_earned".localized()
        segmentedControl.rightItem = "kinecosystem_used".localized()

    }

    fileprivate func setupExtraViews() {
        title = "my_kin".localized()
        let settingsIcon = UIImage(named: "KinNewSettingsIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        let settingsBarButton = UIBarButtonItem(image: settingsIcon,
                                                landscapeImagePhone: nil,
                                                style: .plain,
                                                target: self,
                                                action: #selector(settingsTapped))
        navigationItem.rightBarButtonItem = settingsBarButton
    }

    fileprivate func setupTableView() {
        let nib = UINib(nibName:orderCellName, bundle: KinBundle.ecosystem.rawValue)
        tableView.register(nib, forCellReuseIdentifier: orderCellName)
    }

    fileprivate func setupFRCSections() {


        DispatchQueue.main.async {
            self.tableView.removeTableSection(for: 0)
            let request = NSFetchRequest<Order>(entityName: "Order")
            request.sortDescriptors = [NSSortDescriptor(key: "completion_date", ascending: false)]
            let offerTypeDescriptor = self.offerType == .earn ? "earn" : "spend"
            print("offerTypeDescriptor",offerTypeDescriptor)
            request.predicate = (!NSPredicate(with: ["status" : OrderStatus.pending.rawValue])
                .or(["status" : OrderStatus.delayed.rawValue]))
                .and(["offer_type" : offerTypeDescriptor])
            let frc = NSFetchedResultsController<NSManagedObject>(fetchRequest: request as! NSFetchRequest<NSManagedObject>,
                                                                  managedObjectContext: self.core.data.stack.viewContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)

            let section = FetchedResultsTableSection(table: self.tableView, frc: frc) { [weak self] cell, ip in
                guard   let this = self,
                    let theme = this.theme,
                    let order = this.tableView.objectForTable(at: ip) as? Order,
                    let orderCell = cell as? OrderCell else {
                        logWarn("cell configure failed")
                        return
                }

                orderCell.selectionStyle = .none
                var viewModel: OrderViewModel
                if let orderViewModel = this.orderViewModels[order.id] {
                    viewModel = orderViewModel
                } else {
                    viewModel = OrderViewModel(with: order,
                                               theme: theme,
                                               last: ip.row == (this.tableView.tableSection(for: ip.section)?.objectCount)! - 1,
                                               first: ip.row == 0)
                    this.orderViewModels[order.id] = viewModel
                }

                orderCell.failed.attributedText = viewModel.failed
                orderCell.amount.attributedText = viewModel.amount
                orderCell.title.attributedText = viewModel.title
                orderCell.subtitle.attributedText = viewModel.subtitle
                orderCell.last = viewModel.last
                orderCell.first = viewModel.first
                orderCell.icon = viewModel.icon
            }

            self.tableView.add(tableSection: section)
           // try? frc.performFetch()

            self.tableView.reloadData()

            if section.objectCount == 0 {
                self.segmentedControl.isEnabled = true
            }

        }
    }

    func presentCoupon(for order: Order) {
        guard   let couponCode = (order.result as? CouponCode)?.coupon_code,
                let data =  order.content?.data(using: .utf8),
                let viewModel = try? JSONDecoder().decode(CouponViewModel.self, from: data) else {
            logError("offer content is not in the correct format")
            return
        }
        Kin.track { try OrderHistoryItemTapped(offerID: order.offer_id, orderID: order.id) }
        viewModel.coupon_code = couponCode
        presentCoupon(with: viewModel, biData: CouponViewController.BIData(offerId: order.offer_id, orderId: order.id, amount: Double(order.amount), trigger: .userInit))
    }

    func presentCoupon(with viewModel: CouponViewModel, biData: CouponViewController.BIData) {
        
    }

    @objc fileprivate func settingsTapped() {
        delegate?.ordersViewControllerDidTapSettings()
    }

    @IBAction func segmedControlChangedValue(_ sender: Any) {
          segmentedControl.isEnabled = false
        offerType = segmentedControl.selectedSegmentIndex == 0 ? .earn : .spend
    }
}

@available(iOS 9.0, *)
extension OrdersViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tableSection(for: section)?.objectCount ?? 0
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
            segmentedControl.isEnabled = true
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: orderCellName, for: indexPath)
        let section = tableView.tableSection(for: indexPath.section)
        section?.configureBlock?(cell, indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard   let order = tableView.objectForTable(at: indexPath) as? Order else {
                logError("offer content is not in the correct format")
                return
        }
        presentCoupon(for: order)
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
}

extension OrdersViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        navigationController?.navigationBar.titleTextAttributes = theme.title20.attributes
    }
}
