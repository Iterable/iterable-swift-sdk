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
    @IBOutlet weak var errorLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func replaceCurlyQuotes(in string: String) -> String {
        return string
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
    }
    
    @IBAction func trackEventBtnClicked() {
//        let jsonString = "{\"url\": \"vvv\", \"sku\": \"skuID\", \"name\": \"nnn\", \"price\": 22, \"quantity\": 22}"
        
        guard var jsonString = trakEventTextField.text else {
            errorLabel.text = "Invalid input"
            print("Invalid input")
            return
        }

        jsonString = replaceCurlyQuotes(in: jsonString)
        if let jsonDictionary = convertJsonToDictionary(jsonString: jsonString) {
            guard let eventName = jsonDictionary["eventName"] as? String else {
                       errorLabel.text = "eventName not found in JSON"
                       print("eventName not found in JSON")
                       return
                   }
            
            guard let dataFields = jsonDictionary["dataFields"] as? [String: Any] else {
                       errorLabel.text = "dataFields not found in JSON"
                       print("dataFields not found in JSON")
                       return
                   }
          
            print("vvvv dataFields \(dataFields)")
            IterableAPI.track(event: eventName, dataFields: dataFields)
        } else {
            errorLabel.text = "Failed to convert JSON to dictionary"
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func trackPurchaseBtnClicked() {
        guard var jsonString = trakPurchaseTextField.text else {
            errorLabel.text = "Invalid input"
            print("Invalid input")
            return
        }

        jsonString = replaceCurlyQuotes(in: jsonString)
        if let dictionary = convertJsonToDictionary(jsonString: jsonString) {
            guard let total = dictionary["total"] as? NSNumber else {
                   errorLabel.text = "'total' is missing in JSON"
                   print("Error: 'total' is missing in JSON")
                   return
            }
            
            if let commerceItem = createCommerceItem(from: dictionary) {
                print("CommerceItem created: \(commerceItem.count)")
                if commerceItem.count > 0 {
                    errorLabel.text = ""
                    IterableAPI.track(purchase:  total, items: commerceItem)
                }
            } else {
                errorLabel.text = "Failed to create CommerceItem"
                print("Failed to create CommerceItem")
            }
        } else {
            errorLabel.text = "Failed to convert JSON to dictionary"
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func updateCartBtnClicked() {
        guard var jsonString = updateCartTextField.text else {
            errorLabel.text = "Invalid input"
            print("Invalid input")
            return
        }

        jsonString = replaceCurlyQuotes(in: jsonString)
        if let dictionary = convertJsonToDictionary(jsonString: jsonString) {
            if let commerceItem = createCommerceItem(from: dictionary) {
                print("CommerceItem created: \(commerceItem.count)")
                if commerceItem.count > 0 {
                    errorLabel.text = ""
                    IterableAPI.updateCart(items: commerceItem)
                }
            } else {
                errorLabel.text = "Failed to create CommerceItem"
                print("Failed to create CommerceItem")
            }
        } else {
            errorLabel.text = "Failed to convert JSON to dictionary"
            print("Failed to convert JSON to dictionary")
        }
    }
    
    @IBAction func updateUserBtnClicked() {
        guard var jsonString = updateUserTextField.text else {
            errorLabel.text = "Invalid input"
            print("Invalid input")
            return
        }

        jsonString = replaceCurlyQuotes(in: jsonString)
        if let jsonDictionary = convertJsonToDictionary(jsonString: jsonString) {
            print("update user\(jsonDictionary)")
            errorLabel.text = ""
            IterableAPI.updateUser(jsonDictionary, mergeNestedObjects: true)

        } else {
            errorLabel.text = "Failed to convert JSON to dictionary"
            print("Failed to convert JSON to dictionary")
        }
    }
    
    func convertJsonToDictionary(jsonString: String) -> [String: Any]? {
        print("vvvv json\(jsonString)")
        if let data = jsonString.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch let error {
                errorLabel.text = "Error converting JSON to dictionary"
                print("Error converting JSON to dictionary: \(error.localizedDescription)")
            }
        }
        return nil
    }
    func createCommerceItem(from dictionary: [String: Any]) -> [CommerceItem]? {
        guard let itemsArray = dictionary["items"] as? [[String: Any]] else {
            errorLabel.text = "Please enter items"
            print("Please enter items")
              return nil
          }

          return itemsArray.compactMap { itemDict in
              let id = itemDict["id"] as? String
                     let name = itemDict["name"] as? String
                     let price = itemDict["price"] as? NSNumber
                     let quantity = itemDict["quantity"] as? NSNumber
              
              guard
                  let itemId = id,
                  let itemName = name,
                  let itemPrice = price,
                  let itemQuantity = quantity
              else {
                errorLabel.text = "Please enter id, name, price and quantity in Items"
                print("Please enter id, name, price and quantity in Items")
                return nil
              }
              
              return CommerceItem(
                id: itemDict["id"] as? String ?? "",
                name: itemDict["name"] as? String ?? "",
                price: itemDict["price"] as? NSNumber ?? 0,
                quantity: itemDict["quantity"] as? UInt ?? 0,
                sku: itemDict["sku"] as? String,
                description: itemDict["description"] as? String,
                url: itemDict["url"] as? String,
                imageUrl: itemDict["imageUrl"] as? String,
                categories: itemDict["categories"] as? [String],
                dataFields: itemDict["dataFields"] as? [String: Any]
              )
          }
    }
    
}

