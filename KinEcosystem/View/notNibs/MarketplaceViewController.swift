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

class MarketplaceViewController: KinNavigationChildController {
    
    weak var core: Core!
    
    fileprivate(set) var offerViewModels = [String : OfferViewModel]()
    fileprivate let earnCellName = "EarnOfferCell"
    fileprivate let spendCellName = "SpendOfferCell"
    fileprivate weak var htmlController: EarnOfferViewController?
    fileprivate var openOrder: OpenOrder?
    fileprivate var htmlResult: String?
    fileprivate let bag = LinkBag()
    fileprivate var balanceSnapshot: Decimal = 0
    @IBOutlet weak var earnOffersCollectionView: UICollectionView!
    @IBOutlet weak var spendOffersCollectionView: UICollectionView!
    
    fileprivate var firstSpendSubmitted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionViews()
        setupFRCSections()
        setupNavigationItem()
        setupBalanceWatch()
    }
    
    fileprivate func setupBalanceWatch() {
        core.blockchain.currentBalance.on(queue: .main, next: { [weak self] balanceState in
            guard let this = self else { return }
            switch balanceState {
            case let .pendind(value):
                this.balanceSnapshot = value
            case let .errored(value):
                this.balanceSnapshot = value
            case let .verified(value):
                this.balanceSnapshot = value
            }
        }).add(to: bag)
    }
    
    fileprivate func setupNavigationItem() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = "Kin Marketplace"
        let item = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close))
        item.tintColor = .white
        navigationItem.rightBarButtonItem = item
    }
    
    fileprivate func resultsController(for offerType: OfferType) -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<Offer>(entityName: "Offer")
        request.predicate = NSPredicate(with: ["offer_type" : offerType.rawValue,
                                               "pending" : false])
        request.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
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
    
    @objc func close() {
        Kin.shared.closeMarketPlace()
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
        
        guard let offer = collectionView.objectForCollection(at: indexPath) as? Offer else { return }
        
        switch offer.offerType {
        case .earn:
            let html = EarnOfferViewController()
            html.core = core
            html.offerId = offer.id
            html.title = offer.title
            htmlController = html
            let navContoller = KinBaseNavigationController(rootViewController: html)
            self.kinNavigationController?.present(navContoller, animated: true)
            Flows.earn(offerId: offer.id, resultPromise: html.earn, core: core)
        default: // spend
            guard   let data = offer.content.data(using: .utf8),
                    let viewModel = try? JSONDecoder().decode(SpendViewModel.self, from: data) else {
                        logError("offer content is not in the correct format")
                        return
            }
            guard balanceSnapshot >= Decimal(offer.amount) else {
                let transition = SheetTransition()
                let controller = InsufficientFundsViewController(nibName: "InsufficientFundsViewController",
                                                                 bundle: Bundle.ecosystem)
                controller.modalPresentationStyle = .custom
                controller.transitioningDelegate = transition
                self.kinNavigationController?.present(controller, animated: true)
                return
            }
            let controller = SpendOfferViewController(nibName: "SpendOfferViewController",
                                                      bundle: Bundle.ecosystem)
            controller.viewModel = viewModel
            let transition = SheetTransition()
            controller.modalPresentationStyle = .custom
            controller.transitioningDelegate = transition
            self.kinNavigationController?.present(controller, animated: true)
            
            var submissionPromise: Promise<Void>? = nil
            var successPromise: Promise<Order>? = nil
            
            if firstSpendSubmitted == false {
                firstSpendSubmitted = true
                submissionPromise = Promise<Void>()
                successPromise = Promise<Order>()
                submissionPromise!.then { [weak self] in
                    guard let this = self else { return }
                    DispatchQueue.main.async {
                        this.kinNavigationController?.transitionToOrders()
                    }
                }
                successPromise!.then { [weak self] order in
                    guard let this = self else { return }
                    DispatchQueue.main.async {
                        if let ordersController = this.kinNavigationController?.kinChildViewControllers.last as? OrdersViewController {
                            ordersController.presentCoupon(for: order)
                        }
                    }
                }
            }
            
            Flows.spend(offerId: offer.id,
                        confirmPromise: controller.spend,
                        submissionPromise: submissionPromise,
                        successPromise: successPromise,
                        core: core)
            
            
        }
        
        
        
    }
}

