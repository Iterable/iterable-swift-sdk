//
//  CoffeeViewController.swift
//  iOS Demo
//
//  Created by Tapash Majumder on 5/23/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class CoffeeViewController: UIViewController {
    @IBOutlet weak var coffeeLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buyBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var coffee: CoffeeType?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let coffee = coffee else {
            return
        }
        
        coffeeLbl.text = coffee.name
        imageView.image = coffee.image
    }
    
    @IBAction func handleBuyButtonTap(_ sender: Any) {
        guard let coffee = coffee else {
            return
        }
        
        let attributionInfo = IterableAPI.instance?.attributionInfo
        
        var dataFields = Dictionary<String, Any>()
        if let attributionInfo = attributionInfo {
            dataFields["campaignId"] = attributionInfo.campaignId
            dataFields["templateId"] = attributionInfo.templateId
            dataFields["messageId"] = attributionInfo.messageId
        }
        //ITBL: Track attribution to purchase
        IterableAPI.instance?.trackPurchase(10.0, items: [CommerceItem(id: coffee.name.lowercased(), name: coffee.name, price: 10.0, quantity: 1)], dataFields: dataFields)
    }
}

extension CoffeeViewController : StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeViewController"
}
