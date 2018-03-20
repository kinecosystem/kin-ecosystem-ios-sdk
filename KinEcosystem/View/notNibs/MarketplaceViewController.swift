//
//  MarketplaceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 13/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import StellarKit
import KinSDK
import KinUtil

fileprivate struct EarnPromiseHelper {
    weak var this: MarketplaceViewController?
    var openOrder: OpenOrder?
    var htmlResult: String?
    var memo: PaymentMemoIdentifier?
}

class MarketplaceViewController: KinNavigationChildController {
    
    weak var core: Core!
    
    fileprivate(set) var offerViewModels = [String : OfferViewModel]()
    fileprivate let earnCellName = "EarnOfferCell"
    fileprivate let spendCellName = "SpendOfferCell"
    fileprivate weak var htmlController: EarnOfferViewController?
    fileprivate var openOrder: OpenOrder?
    fileprivate var htmlResult: String?
    @IBOutlet weak var earnOffersCollectionView: UICollectionView!
    @IBOutlet weak var spendOffersCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionViews()
        setupFRCSections()
        setupNavigationItem()
        
    }
    
    fileprivate func setupNavigationItem() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.title = "Kin Marketplace"
    }
    
    fileprivate func resultsController(for offerType: OfferType) -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<Offer>(entityName: "Offer")
        request.predicate = NSPredicate(with: ["offer_type" : offerType.rawValue])
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let frc = NSFetchedResultsController<NSManagedObject>(fetchRequest: request as! NSFetchRequest<NSManagedObject>, managedObjectContext: core.data.stack.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? frc.performFetch()
        return frc
    }
    
    fileprivate func setupFRCSections() {
        let earnSection = FetchedResultsCollectionSection(collection: earnOffersCollectionView, frc: resultsController(for: .earn)) { [weak self] cell, ip in
            guard   let this = self,
                let offer = this.earnOffersCollectionView.objectForCollection(at: ip) as? Offer,
                let earnCell = cell as? EarnOfferCell else {
                    logWarn("cell configure failed")
                    return
            }
            
            var viewModel: OfferViewModel
            if let offerViewModel = this.offerViewModels[offer.id] {
                viewModel = offerViewModel
            } else {
                viewModel = OfferViewModel(with: offer)
                this.offerViewModels[offer.id] = viewModel
            }
            earnCell.title.attributedText = viewModel.title
            earnCell.imageView.image = nil
            viewModel.image.then(on: .main) { [weak earnCell] result in
                earnCell?.imageView.image = result.image
                }.error { error in
                    logWarn("cell image error: \(error)")
            }
            earnCell.amount.attributedText = viewModel.amount
            earnCell.subtitle.attributedText = viewModel.subtitle
        }
        earnOffersCollectionView.add(fetchedResultsSection: earnSection)
        
        let spendSection = FetchedResultsCollectionSection(collection: spendOffersCollectionView, frc: resultsController(for: .spend)) { [weak self] cell, ip in
            guard   let this = self,
                let offer = this.spendOffersCollectionView.objectForCollection(at: ip) as? Offer,
                let spendCell = cell as? SpendOfferCell else {
                    logWarn("cell configure failed")
                    return
            }
            
            var viewModel: OfferViewModel
            if let offerViewModel = this.offerViewModels[offer.id] {
                viewModel = offerViewModel
            } else {
                viewModel = OfferViewModel(with: offer)
                this.offerViewModels[offer.id] = viewModel
            }
            spendCell.title.attributedText = viewModel.title
            spendCell.imageView.image = nil
            viewModel.image.then(on: .main) { [weak spendCell] result in
                spendCell?.imageView.image = result.image
                }.error { error in
                    logWarn("cell image error: \(error)")
            }
            spendCell.amount.attributedText = viewModel.amount
            spendCell.subtitle.attributedText = viewModel.subtitle
        }
        spendOffersCollectionView.add(fetchedResultsSection: spendSection)
    }
    
    fileprivate func setupCollectionViews() {
        earnOffersCollectionView.contentInset = .zero
        earnOffersCollectionView.register(UINib(nibName: earnCellName, bundle: Bundle.ecosystem),
                                          forCellWithReuseIdentifier: earnCellName)
        earnOffersCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
        spendOffersCollectionView.contentInset = .zero
        spendOffersCollectionView.register(UINib(nibName: spendCellName, bundle: Bundle.ecosystem),
                                           forCellWithReuseIdentifier: spendCellName)
        spendOffersCollectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    fileprivate func earn(with controller: EarnOfferViewController) {
        
        // this is beautyful if you don't like it you're a hater
        core.network.objectAtPath("offers/\(controller.offerId!)/orders", type: OpenOrder.self, method: .post)
            .then { [weak self] order -> Promise<(String, OpenOrder)> in
                guard let this = self else { throw KinError.internalInconsistency }
                this.openOrder = order
                return controller.earn
                    .then { htmlResult in
                        Promise<(String, OpenOrder)>().signal((htmlResult, order))
                }
            }.then(on: .main) { [weak self] htmlResult, order -> Promise<(String, OpenOrder, PaymentMemoIdentifier, Core)> in
                guard let this = self else { throw KinError.internalInconsistency }
                if let controller = this.htmlController {
                    controller.dismiss(animated: true) {
                        this.htmlController = nil
                    }
                }
                let memo = PaymentMemoIdentifier(appId: this.core.network.client.config.appId,
                                                 id: order.id)
                return Promise<(String, OpenOrder, PaymentMemoIdentifier, Core)>().signal((htmlResult, order, memo, this.core))
            }.then { htmlResult, order, memo, core in
                try core.blockchain.startWatchingForNewPayments(with: memo)
            }.then { htmlResult, order, memo, core -> Promise<(Data, PaymentMemoIdentifier, Core)> in
                let result = EarnResult(content: htmlResult)
                let content = try JSONEncoder().encode(result)
                return core.network.dataAtPath("orders/\(order.id)", method: .post, body: content)
                    .then { data in
                        Promise<(Data, PaymentMemoIdentifier, Core)>().signal((data, memo, core))
                }
            }.then { [weak self] data, memo, core -> Promise<(PaymentMemoIdentifier, Core)> in
                self?.openOrder = nil
                return core.data.save(Order.self, with: data)
                    .then {
                        Promise<(PaymentMemoIdentifier, Core)>().signal((memo, core))
                }
            }.then { memo, core -> Promise<(PaymentMemoIdentifier, Core)> in
                return core.blockchain.waitForNewPayment(with: memo)
                    .then {
                        Promise<(PaymentMemoIdentifier, Core)>().signal((memo, core))
                }
            }.then { memo, core in
                core.blockchain.stopWatchingForNewPayments(with: memo)
            }.error { error in
                if case let EarnOfferHTMLError.js(jsError) = error {
                    logError("earn flow JS error: \(jsError)")
                } else {
                    switch error {
                    case is KinError,
                         is BlockchainError:
                        Kin.shared.core?.blockchain.stopWatchingForNewPayments()
                        logError("earn flow error: \(error)")
                    default:
                        logError("earn flow error: \(error)")
                    }
                }
            }.finally { [weak self] in
                if let order = self?.openOrder {
                    self?.core.network.delete("orders/\(order.id)").then {
                        logInfo("order canceled: \(order.id)")
                        }.error { error in
                            logError("error canceling order: \(order.id)")
                    }
                }
                self?.openOrder = nil
                if let controller = self?.htmlController {
                    DispatchQueue.main.async {
                        controller.dismiss(animated: true) {
                            self?.htmlController = nil
                        }
                    }
                    
                }
        }
        
    }

}

extension MarketplaceViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView {
        case earnOffersCollectionView:
            return earnOffersCollectionView.fetchedResultsSectionCount
        case spendOffersCollectionView:
            return spendOffersCollectionView.fetchedResultsSectionCount
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case earnOffersCollectionView:
            return earnOffersCollectionView.fetchedResultsSection(for: section)?.objectCount ?? 0
        case spendOffersCollectionView:
            return spendOffersCollectionView.fetchedResultsSection(for: section)?.objectCount ?? 0
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cellIdentifier: String
        switch collectionView {
        case earnOffersCollectionView:
            cellIdentifier = earnCellName
        case spendOffersCollectionView:
            cellIdentifier = spendCellName
        default:
            cellIdentifier = ""
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        let frcSection = collectionView.fetchedResultsSection(for: indexPath.section)
        frcSection?.configureBlock?(cell, indexPath)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let offer = collectionView.objectForCollection(at: indexPath) as? Offer {
            let html = EarnOfferViewController()
            html.core = core
            html.offerId = offer.id
            htmlController = html
            self.kinNavigationController?.present(html, animated: true)
            self.earn(with: html)
        }
    }
}

