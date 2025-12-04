//
//  CoffeeViewController.swift
//  iOS Demo
//
//  Created by Tapash Majumder on 5/23/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit
import WebKit

import IterableSDK

class CoffeeViewController: UIViewController, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "textHandler",
           let text = message.body as? String {

            print("Received from HTML:", text)

            // Show native alert.
            let alert = UIAlertController(
                title: "Applied Additional 10% Bonus Discount!",
                message: "Zip Code: "+text,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @IBOutlet weak var coffeeLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buyBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var coffee: CoffeeType?
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let coffee = coffee else {
            return
        }
        
        coffeeLbl.text = coffee.name
        imageView.image = coffee.image
        
        // Add JS message handler
        let contentController = WKUserContentController()
        contentController.add(self, name: "textHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        loadInlineHTML()
    }
    
    private func loadInlineHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <body>

        <h1>Get Additional Local Discounts</h1>
        <input id="myInput" type="text" placeholder="Type in your zip code…" />
        <button onclick="sendToiOS()">Apply</button>

        <script>
        function sendToiOS() {
            var text = document.getElementById("myInput").value;
            window.webkit.messageHandlers.textHandler.postMessage(text);
        }
        </script>

        </body>
        </html>
        """

        // Base URL is required for JS to run correctly
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    @IBAction func handleBuyButtonTap(_: Any) {
        guard let coffee = coffee else {
            return
        }
        
        let attributionInfo = IterableAPI.attributionInfo
        
        var dataFields = [String: Any]()
        if let attributionInfo = attributionInfo {
            dataFields["campaignId"] = attributionInfo.campaignId
            dataFields["templateId"] = attributionInfo.templateId
            dataFields["messageId"] = attributionInfo.messageId
        }
        
        // ITBL: Track attribution to purchase
        IterableAPI.track(purchase: 10.0, items: [CommerceItem(id: coffee.name.lowercased(), name: coffee.name, price: 10.0, quantity: 1)], dataFields: dataFields)
    }
}

extension CoffeeViewController: StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeViewController"
}
