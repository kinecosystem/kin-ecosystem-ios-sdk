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

class OffersList: Codable {
    
    var offers: [Offer]
    
}

class Offer: NSManagedObject, Decodable {
    
    /*
     
     {
         "id": "spend_offer1.png",
         "title": "Gift Card",
         "description": "$10 gift card",
         "image": "https://s3.amazonaws.com/kinmarketplace-assets/version1/spend_offer1.png",
         "amount": 8000,
         "content": {
             "content_type": "Coupon",
             "description": "aaa-bbb-ccc-ddd"
         },
         "offer_type": "spend"
     }
     
    */

    @NSManaged public var amount: Int32
    @NSManaged public var description_: String
    @NSManaged public var id: String
    @NSManaged public var image: String
    @NSManaged public var offer_type: String
    @NSManaged public var title: String
    
    var offerType: OfferType {
        get { return OfferType(rawValue: offer_type)! }
        set { offer_type = newValue.rawValue }
    }
    
    enum OfferKeys: String, CodingKey {
        case amount
        case description
        case id
        case image
        case offer_type
        case title
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Offer", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: nil)
        let values = try decoder.container(keyedBy: OfferKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        description_ = try values.decode(String.self, forKey: .description)
        image = try values.decode(String.self, forKey: .image)
        amount = try values.decode(Int32.self, forKey: .amount)
        offer_type = try values.decode(String.self, forKey: .offer_type)
    }
    
    func update(_ from: Offer) {
        amount = from.amount
        description_ = from.description_
        offer_type = from.offer_type
        image = from.image
        title = from.title
    }
    
}

extension Offer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OfferKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description_, forKey: .description)
        try container.encode(image, forKey: .id)
        try container.encode(amount, forKey: .amount)
        try container.encode(offer_type, forKey: .offer_type)
    }
}







