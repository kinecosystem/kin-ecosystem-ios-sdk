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
    func offersViewController(_ controller: OffersViewController, didTap offer: Offer)
    func offersViewControllerDidTapMyKinButton()
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
    weak var delegate: OffersViewControllerDelegate?

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
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "closeBtn",
                                                                          in: KinBundle.ecosystem.rawValue,
                                                                          compatibleWith: nil),
                                                           style: .plain) { [weak self] in
                                                            self?.delegate?.offersViewControllerDidTapCloseButton()
        }
        navigationItem.titleView = balanceView
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: nil, style: .plain) { [weak self] in
            self?.delegate?.offersViewControllerDidTapMyKinButton()
        }
        setupTheming()
        setupCollectionView()
        setupFRCSection()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSettingsBadgeIfNeeded()
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

    fileprivate func updateSettingsBadgeIfNeeded() {
        guard
            let theme = theme,
            let settingsImage = UIImage.bundleImage(theme.settingsIconImageName),
            let badgeImage = UIImage.bundleImage(theme.settingsIconBadgeImageName) else {
                return
        }

        let isBackedUp = core.blockchain.isBackedUp
        let hasSeenTransfer = Kin.shared.hasSeenTransfer

        func setSettingsImage(withBadge: Bool) {
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.image =
                    withBadge
                    ? settingsImage.overlayed(with: badgeImage)?.withRenderingMode(.alwaysOriginal)
                    : settingsImage.withRenderingMode(.alwaysOriginal)
            }
        }

        if !isBackedUp && hasSeenTransfer {
            core.blockchain.balance().then { [weak self] balance in
                setSettingsImage(withBadge: balance > 0)
            }
        } else {
            setSettingsImage(withBadge: !hasSeenTransfer)
        }
    }
}

extension OffersViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        titleLabel.attributedText = "what_are_you_in_the_mood_for".localized().styled(as: theme.title20)
        navigationItem.leftBarButtonItem?.tintColor = theme.closeButtonTint
        navigationItem.rightBarButtonItem?.image = UIImage.bundleImage(theme.settingsIconImageName)?.withRenderingMode(.alwaysOriginal)
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
        delegate?.offersViewController(self, didTap: offer)
    }
    
    func updateCollectionView(_ cv: UICollectionView, for numOfOffers: Int) {
        let hasOffers = numOfOffers > 0
        cv.isHidden = !hasOffers
        titleLabel.isHidden = !hasOffers

        if hasOffers {
            if let noOffersViewController = children.first(where: { $0 is NoOffersViewController }) {
                noOffersViewController.willMove(toParent: nil)
                noOffersViewController.removeFromParent()
                noOffersViewController.view.removeFromSuperview()
            }
        } else {
            if children.first(where: { $0 is NoOffersViewController }) == nil {
                let noOffersViewController = NoOffersViewController(nibName: "NoOffersViewController", bundle: KinBundle.ecosystem.rawValue)
                addChild(noOffersViewController)
                view.addSubview(noOffersViewController.view)
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: noOffersViewController.view.topAnchor),
                    view.leftAnchor.constraint(equalTo: noOffersViewController.view.leftAnchor),
                    view.rightAnchor.constraint(equalTo: noOffersViewController.view.rightAnchor),
                    view.bottomAnchor.constraint(equalTo: noOffersViewController.view.bottomAnchor)
                    ])
                noOffersViewController.didMove(toParent: self)
            }
        }
    }
}
