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

class MarketplaceViewController: UIViewController {

    weak var data: EcosystemData!
    weak var network: EcosystemNet!
    fileprivate(set) var offerViewModels = [String : OfferViewModel]()
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    fileprivate let cellName = "EarnOfferCell"
    @IBOutlet weak var earnOffersCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // collection view
        
        earnOffersCollectionView.contentInset = .zero
        earnOffersCollectionView.register(UINib(nibName: cellName, bundle: Bundle.ecosystem), forCellWithReuseIdentifier: cellName)
        
        // frc
        
        let section = FetchedResultsCollectionSection(collection: earnOffersCollectionView, frc: resultsController()) { [weak self] cell, ip in
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
            earnCell.title.text = viewModel.title
            earnCell.imageView.image = nil
            viewModel.image.then(on: DispatchQueue.main) { [weak earnCell] result in
                earnCell?.imageView.image = result.image
                }.error { error in
                    logWarn("cell image error: \(error)")
            }
            earnCell.amount.text = "\(viewModel.amount) Kin"
            earnCell.subtitle.text = viewModel.description
        }
        earnOffersCollectionView.add(fetchedResultsSection: section)
        
        // dependencies
        
        network.offers()
            .then { data in
                self.data.syncOffersFromNetworkData(data: data)
            }.then(on: DispatchQueue.main) {
                self.earnOffersCollectionView.reloadData()
            }.error { error in
                logError("error getting offers data")
        }
        
        // controller
        
        self.title = "Kin Marketplace"
    }
    
    func resultsController() -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<Offer>(entityName: Offer.entityName)
        request.predicate = NSPredicate(with: ["offer_type" : OfferType.earn.rawValue])
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let frc = NSFetchedResultsController<NSManagedObject>(fetchRequest: request as! NSFetchRequest<NSManagedObject>, managedObjectContext: data.stack.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? frc.performFetch()
        return frc
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

}

extension MarketplaceViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return earnOffersCollectionView.fetchedResultsSectionCount
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return earnOffersCollectionView.fetchedResultsSection(for: section)?.objectCount ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = earnOffersCollectionView.dequeueReusableCell(withReuseIdentifier: cellName, for: indexPath)
        let frcSection = earnOffersCollectionView.fetchedResultsSection(for: indexPath.section)
        frcSection?.configureBlock?(cell, indexPath)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

