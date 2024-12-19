//
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

/// `CommerceItem` represents a product
/// - SeeAlso: IterableAPI.track(purchase withTotal: items:)
@objcMembers public class CommerceItem: NSObject {
    /// id of this product
    public var id: String
    
    /// name of this product
    public var name: String
    
    /// price of this product
    public var price: NSNumber
    
    /// quantity of this product
    public var quantity: UInt
    
    /// SKU of this product
    public var sku: String?
    
    /// description of the product
    /// the class field is named `itemDescription` to avoid iOS namespace (`description`)
    public var itemDescription: String?
    
    /// URL of the product
    public var url: String?
    
    /// URL of the product's image
    public var imageUrl: String?
    
    /// categories this product belongs to
    /// each category is a breadcrumb in list form
    public var categories: [String]?
    
    /// data fields for this product
    public var dataFields: [AnyHashable: Any]?
    
    /// Creates a `CommerceItem` with the specified properties
    ///
    /// - Parameters:
    ///     - id: id of the product
    ///     - name: name of the product
    ///     - price: price of the product
    ///     - quantity: quantity of the product
    ///     - sku: SKU of the eproduct
    ///     - description: description of the product
    ///     - url: URL of the product
    ///     - imageUrl: URL of the product's image
    ///     - categories: categories this product belongs to
    ///
    /// - returns: an instance of `CommerceItem` with the specified properties
    public init(id: String,
                name: String,
                price: NSNumber,
                quantity: UInt,
                sku: String? = nil,
                description: String? = nil,
                url: String? = nil,
                imageUrl: String? = nil,
                categories: [String]? = nil,
                dataFields: [AnyHashable: Any]? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sku = sku
        self.itemDescription = description
        self.url = url
        self.imageUrl = imageUrl
        self.categories = categories
        self.dataFields = dataFields
    }
    
    /// A `Dictionary` representation of this item
    ///
    /// - returns: An `Dictionary` representing this item
    public func toDictionary() -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [JsonKey.CommerceItem.id: id,
                                              JsonKey.CommerceItem.name: name,
                                              JsonKey.CommerceItem.price: price,
                                              JsonKey.CommerceItem.quantity: quantity]
        
        if let sku = sku {
            dictionary[JsonKey.CommerceItem.sku] = sku
        }
        
        if let description = itemDescription {
            dictionary[JsonKey.CommerceItem.description] = description
        }
        
        if let url = url {
            dictionary[JsonKey.CommerceItem.url] = url
        }
        
        if let imageUrl = imageUrl {
            dictionary[JsonKey.CommerceItem.imageUrl] = imageUrl
        }
        
        if let categories = categories {
            dictionary[JsonKey.CommerceItem.categories] = categories
        }
        
        if let dataFields = dataFields {
            dictionary[JsonKey.CommerceItem.dataFields] = dataFields
        }
        
        return dictionary
    }
}
