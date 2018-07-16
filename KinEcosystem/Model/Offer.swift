//
//
//  Offer.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation
import CoreData

enum OfferType: String {
    case earn
    case spend
}

enum OfferContentType: String {
    case poll
    case coupon
    case external
    case quiz
    case tutorial
}

class OffersList: EntityPresentor {
    typealias entity = Offer
    var offers: [entity]?
    var entities: [entity]? {
        return offers
    }
}

class Offer: NSManagedObject, NetworkSyncable {

    @NSManaged public var amount: Int32
    @NSManaged public var description_: String
    @NSManaged public var id: String
    @NSManaged public var image: String
    @NSManaged public var offer_type: String
    @NSManaged public var content_type: String
    @NSManaged public var content: String
    @NSManaged public var title: String
    @NSManaged public var blockchain_data: BlockchainData?
    // not decoded properties
    @NSManaged public var pending: Bool
    @NSManaged public var position: Int32
    @NSManaged public var isModal: Bool
    
    var offerType: OfferType {
        get { return OfferType(rawValue: offer_type)! }
        set { offer_type = newValue.rawValue }
    }
    
    var offerContentType: OfferContentType {
        get { return OfferContentType(rawValue: content_type)! }
        set { content_type = newValue.rawValue }
    }
    
    enum OfferKeys: String, CodingKey {
        case amount
        case description
        case id
        case image
        case offer_type
        case title
        case content
        case isModal
        case content_type
        case blockchain_data
    }
    
    var nativeOffer: NativeOffer {
        return NativeOffer(id: id,
                           title: title,
                           description: description_,
                           amount: amount,
                           image: image,
                           isModal: isModal)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Offer", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        let values = try decoder.container(keyedBy: OfferKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        description_ = try values.decode(String.self, forKey: .description)
        image = try values.decode(String.self, forKey: .image)
        amount = try values.decode(Int32.self, forKey: .amount)
        offer_type = try values.decode(String.self, forKey: .offer_type)
        content_type = try values.decode(String.self, forKey: .content_type)
        content = try values.decode(String.self, forKey: .content)
        blockchain_data = try values.decodeIfPresent(BlockchainData.self, forKey: .blockchain_data)
    }
    
    convenience init(with nativeOffer: NativeOffer, in managedObjectContext: NSManagedObjectContext) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "Offer", in: managedObjectContext) else {
            throw EcosystemDataError.internalInconsistency
        }
        self.init(entity: entity, insertInto: managedObjectContext)
        id = nativeOffer.id
        title = nativeOffer.title
        description_ = nativeOffer.description
        image = nativeOffer.image
        amount = nativeOffer.amount
        offerType = .spend
        offerContentType = .external
        content = ""
        isModal = nativeOffer.isModal
    }
    
    var syncId: String {
        return id
    }
    
    func update(_ from: Offer, in context: NSManagedObjectContext) {
        guard self != from else { return }
        amount = from.amount
        description_ = from.description_
        offer_type = from.offer_type
        image = from.image
        title = from.title
        content_type = from.content_type
        content =  from.content
        pending = from.pending
        isModal = from.isModal
        position = from.position
        // don't leave dangling relationships
        if let data = blockchain_data, data != from.blockchain_data {
            context.delete(data)
        }
        blockchain_data = from.blockchain_data
    }
    
    func willDelete() -> Bool {
        return offerContentType != .external
    }
}







