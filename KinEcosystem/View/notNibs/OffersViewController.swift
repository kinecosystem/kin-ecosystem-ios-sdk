//
//  OffersViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 03/06/2019.
//

import UIKit
import KinMigrationModule
import CoreDataStack
import CoreData

protocol OffersViewControllerDelegate: class {
    func offersViewControllerDidTapCloseButton()
    func offersViewController(controller: OffersViewController, didTap offer: Offer)
}

class OffersViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var core: Core!
    fileprivate var theme: Theme?
    fileprivate var offerViewModels = [String : OfferViewModel]()
    fileprivate let cellIdentifier = "OfferCell"
    fileprivate weak var htmlController: EarnOfferViewController?
    fileprivate var openOrder: OpenOrder?
    fileprivate var htmlResult: String?
    fileprivate let bag = LinkBag()
    let themeLinkBag = LinkBag()
    let balanceView = BalanceView(64.0, 20.0)
    weak var flowDelegate: OffersViewControllerDelegate?

    init(core: Core) {
        self.core = core
        super.init(nibName: "OffersViewController", bundle: KinBundle.ecosystem.rawValue)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("OffersViewController must be init with core")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("OffersViewController must be init with core")
    }
    
    private func commonInit() {
        loadViewIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "closeBtn",
                                                                          in: KinBundle.ecosystem.rawValue,
                                                                          compatibleWith: nil),
                                                           style: .plain,
                                                           target: nil,
                                                           action: nil)
        navigationItem.leftBarButtonItem?.actionClosure = { [weak self] in
            self?.flowDelegate?.offersViewControllerDidTapCloseButton()
        }
        navigationItem.titleView = balanceView
        setupTheming()
        setupCollectionView()
        setupFRCSection()
    }
    
    fileprivate func setupFRCSection() {
       
        let request = NSFetchRequest<Offer>(entityName: "Offer")
        request.predicate = NSPredicate(with: ["pending" : false])
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "content_type",
                             ascending: true,
                             comparator: { typeA, typeB -> ComparisonResult in
                                if typeA as? String == OfferContentType.tutorial.rawValue {
                                    return .orderedAscending
                                }
                                if typeA as? String == OfferContentType.external.rawValue {
                                    if typeB as? String == OfferContentType.tutorial.rawValue {
                                        return .orderedDescending
                                    } else if typeB as? String == OfferContentType.external.rawValue {
                                        return .orderedSame
                                    }
                                }
                                return .orderedSame
            }),
            NSSortDescriptor(key: "position", ascending: true)
        ]
        
        let controller = NSFetchedResultsController<NSManagedObject>(fetchRequest: request as! NSFetchRequest<NSManagedObject>,
                                                                     managedObjectContext: core.data.stack.viewContext,
                                                                     sectionNameKeyPath: nil,
                                                                     cacheName: nil)
        try? controller.performFetch()
        
        let earnSection = FetchedResultsCollectionSection(collection: collectionView, frc: controller) { [weak self] cell, ip in
            guard   let this = self,
                let offer = this.collectionView.objectForCollection(at: ip) as? Offer,
                let theme = this.theme,
                let cell = cell as? OfferCell else {
                    logWarn("cell configure failed")
                    return
            }
            
            var viewModel: OfferViewModel
            if let offerViewModel = this.offerViewModels[offer.id] {
                viewModel = offerViewModel
            } else {
                viewModel = OfferViewModel(with: offer, theme: theme)
                this.offerViewModels[offer.id] = viewModel
            }
            
            viewModel.setup(cell)
            
        }
        collectionView.add(fetchedResultsSection: earnSection)
    }
    
    fileprivate func setupCollectionView() {
        collectionView.contentInset = .zero
        collectionView.register(UINib(nibName: cellIdentifier, bundle: KinBundle.ecosystem.rawValue),
                                          forCellWithReuseIdentifier: cellIdentifier)
    }

}

extension OffersViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        titleLabel.attributedText = "what_are_you_in_the_mood_for".localized().styled(as: theme.title20)
        navigationItem.leftBarButtonItem?.tintColor = theme.closeButtonTint
    }
}

extension OffersViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionView.fetchedResultsSectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let num  = collectionView.fetchedResultsSection(for: section)?.objectCount ?? 0
        updateCollectionView(collectionView, for: num)
        return num
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        let frcSection = collectionView.fetchedResultsSection(for: indexPath.section)
        frcSection?.configureBlock?(cell, indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let offer = collectionView.objectForCollection(at: indexPath) as? Offer else { return }
        flowDelegate?.offersViewController(controller: self, didTap: offer)

    }
    
    func updateCollectionView(_ cv: UICollectionView, for numOfOffers: Int) {
        cv.backgroundView?.isHidden = numOfOffers > 0
    }
    
}
