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
    }
    
    fileprivate func setupNavigationItem() {
        self.title = "Transaction History"
        let buttonEdit: UIButton = UIButton(type: .custom) as UIButton
        buttonEdit.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonEdit.setImage(UIImage(named: "whatsKin", in: Bundle.ecosystem, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal), for: .normal)
        buttonEdit.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonEdit)
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName:orderCellName, bundle: Bundle.ecosystem), forCellReuseIdentifier: orderCellName)
    }
    
    fileprivate func setupFRCSections() {
        let request = NSFetchRequest<Order>(entityName: "Order")
        request.sortDescriptors = [NSSortDescriptor(key: "completion_date", ascending: false)]
        request.predicate = !NSPredicate(with: ["status" : OrderStatus.pending.rawValue])
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
    
    @objc fileprivate func didTapInfo(sender: Any?) {

    }

}

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
    
    
}
