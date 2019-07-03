//
//  OrdersViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import KinCoreSDK

@available(iOS 9.0, *)
class OrdersViewController : KinNavigationChildController {

    var core: Core!
    
    fileprivate let orderCellName = "OrderCell"
    fileprivate(set) var orderViewModels = [String : OrderViewModel]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupFRCSections()
        setupNavigationItem()
        Kin.track { try OrderHistoryPageViewed() }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WatchOrderNotification"), object: nil)
    }
    
    fileprivate func setupNavigationItem() {
        self.title = "kinecosystem_transaction_history".localized()
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName:orderCellName, bundle: Bundle.ecosystem), forCellReuseIdentifier: orderCellName)
    }
    
    fileprivate func setupFRCSections() {
        let request = NSFetchRequest<Order>(entityName: "Order")
        request.sortDescriptors = [NSSortDescriptor(key: "completion_date", ascending: false)]
        request.predicate = !NSPredicate(with: ["status" : OrderStatus.pending.rawValue]).or(["status" : OrderStatus.delayed.rawValue])
        let frc = NSFetchedResultsController<NSManagedObject>(fetchRequest: request as! NSFetchRequest<NSManagedObject>,
                                                              managedObjectContext: core.data.stack.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        let section = FetchedResultsTableSection(table: tableView, frc: frc) { [weak self] cell, ip in
            guard   let this = self,
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
                viewModel = OrderViewModel(with: order, last: ip.row == (this.tableView.tableSection(for: ip.section)?.objectCount)! - 1)
                this.orderViewModels[order.id] = viewModel
            }
            
            orderCell.amount.attributedText = viewModel.amount
            orderCell.title.attributedText = viewModel.title
            orderCell.subtitle.attributedText = viewModel.subtitle
            orderCell.icon.image = viewModel.image
            orderCell.last = viewModel.last
            orderCell.color = viewModel.color
            
        }
        tableView.add(tableSection: section)
        try? frc.performFetch()
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
        let controller = CouponViewController(nibName: "CouponViewController", bundle: Bundle.ecosystem)
        controller.viewModel = viewModel
        controller.biData = biData
        let transition = SheetTransition()
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = transition
        kinNavigationController?.present(controller, animated: true)
    }

}
@available(iOS 9.0, *)
extension OrdersViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tableSection(for: section)?.objectCount ?? 0
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
    
}
