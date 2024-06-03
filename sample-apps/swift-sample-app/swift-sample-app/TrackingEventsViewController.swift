//
//  TrackingEventsViewController.swift
//  swift-sample-app
//
//  Created by vishwa on 31/05/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
import UIKit

import IterableSDK
import IterableAppExtensions

class TrackingEventsViewController: UIViewController {
    
    @IBOutlet weak var trakEventTextField: UITextField!
    @IBOutlet weak var trakPurchaseTextField: UITextField!
    @IBOutlet weak var updateCartTextField: UITextField!
    @IBOutlet weak var updateUserTextField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func trackEventBtnClicked() {
//        let jsonString = "{\"url\": \"vvv\", \"sku\": \"skuID\", \"name\": \"nnn\", \"price\": 22, \"quantity\": 22}"
        
        guard let jsonString = trakEventTextField.text else {
            print("Invalid input")
            return
        }

        if let jsonDictionary = convertJsonToDictionary(jsonString: jsonString) {
            // Use the resulting dictionary
                    var dictionary: [AnyHashable: Any] = [:]
                    for (key, value) in jsonDictionary {
                        dictionary[key] = value
                    }
            IterableAPI.track(event: "button-clicked", dataFields: dictionary)
        } else {
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func trackPurchaseBtnClicked() {
        guard let jsonString = trakPurchaseTextField.text else {
            print("Invalid input")
            return
        }

        if let dictionary = convertJsonToDictionary(jsonString: jsonString) {
            if let commerceItem = createCommerceItem(from: dictionary) {
                print("CommerceItem created: \(commerceItem)")
                IterableAPI.track(purchase: 200, items: [commerceItem])
            } else {
                print("Failed to create CommerceItem")
            }
        } else {
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func updateCartBtnClicked() {
        guard let jsonString = updateCartTextField.text else {
            print("Invalid input")
            return
        }

        if let dictionary = convertJsonToDictionary(jsonString: jsonString) {
            if let commerceItem = createCommerceItem(from: dictionary) {
                print("CommerceItem created: \(commerceItem)")
                IterableAPI.updateCart(items: [commerceItem])
            } else {
                print("Failed to create CommerceItem")
            }
        } else {
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func updateUserBtnClicked() {
        guard let jsonString = updateUserTextField.text else {
            print("Invalid input")
            return
        }

        if let jsonDictionary = convertJsonToDictionary(jsonString: jsonString) {
            // Use the resulting dictionary
                    var dictionary: [AnyHashable: Any] = [:]
                    for (key, value) in jsonDictionary {
                        dictionary[key] = value
                    }
            IterableAPI.updateUser(dictionary, mergeNestedObjects: true)

        } else {
            print("Failed to convert JSON to dictionary")
        }
    }
    
    func convertJsonToDictionary(jsonString: String) -> [String: Any]? {
        print("vvvv json\(jsonString)")
        if let data = jsonString.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch let error {
                print("Error converting JSON to dictionary: \(error.localizedDescription)")
            }
        }
        return nil
    }
    func createCommerceItem(from dictionary: [String: Any]) -> CommerceItem? {
        guard let name = dictionary["name"] as? String,
              let price = dictionary["price"] as? NSNumber,
              let quantity = dictionary["quantity"] as? UInt else {
            print("Invalid or missing fields in JSON")
            return nil
        }

        let id = dictionary["id"] as? String ?? ""
        let sku = dictionary["sku"] as? String
        let itemDescription = dictionary["itemDescription"] as? String
        let url = dictionary["url"] as? String
        let imageUrl = dictionary["imageUrl"] as? String
        let categories = dictionary["categories"] as? [String]
        let dataFields = dictionary["dataFields"] as? [AnyHashable: Any]

        return CommerceItem(id: id, name: name, price: price, quantity: quantity, sku: sku, description: itemDescription, url: url, imageUrl: imageUrl, categories: categories, dataFields: dataFields)
    }
    
}

