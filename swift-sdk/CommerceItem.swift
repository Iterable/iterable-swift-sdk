//
//  Created by Tapash Majumder on 6/6/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

/**
 `CommerceItem` represents a product. These are used by the commerce API; see [IterableAPI trackPurchase:items:dataFields:]
 */
@objc public class CommerceItem: NSObject {
    /** id of this product */
    @objc public var id: String
    
    /** name of this product */
    @objc public var name: String
    
    /** price of this product */
    @objc public var price: NSNumber
    
    /** quantity of this product */
    @objc public var quantity: UInt
    
    /**
     Creates a `CommerceItem` with the specified properties
     
     - parameters:
     - id:          id of the product
     - name:        name of the product
     - price:       price of the product
     - quantity:    quantity of the product
     
     - returns: an instance of `CommerceItem` with the specified properties
     */
    @objc public init(id: String, name: String, price: NSNumber, quantity: UInt) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
    
    /**
     A Dictionary respresentation of this item
     
     - returns: An NSDictionary representing this item
     */
    @objc public func toDictionary() -> [AnyHashable: Any] {
        return ["id": id,
                "name": name,
                "price": price,
                "quantity": quantity]
    }
}
