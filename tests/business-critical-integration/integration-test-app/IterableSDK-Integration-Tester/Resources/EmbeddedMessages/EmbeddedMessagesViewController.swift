//
//  EmbeddedMessagesViewController.swift
//  swift-sample-app
//
//  Created by HARDIK MASHRU on 31/10/23.
//  Copyright © 2023 Iterable. All rights reserved.
//

import UIKit
import IterableSDK

struct Placement: Codable {
    let placementId: Int?
    let embeddedMessages: [IterableEmbeddedMessage]
}

struct PlacementsPayload: Codable {
    let placements: [Placement]
}

class EmbeddedMessagesViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var embeddedBannerView: UIView!
    @IBOutlet weak var carouselCollectionView: UICollectionView!
    var cardViews: [IterableEmbeddedMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        embeddedBannerView.isHidden = true
        // loadEmeddedMessages() // Load messages using SDK getMessages
        loadEmbeddedMessagesFromJSON() // Load messages from static JSON
    }
    
    func loadEmbeddedMessagesFromJSON() {
        if let jsonData = loadEmbeededMessagesJSON() {
            do {
                let response = try JSONDecoder().decode(PlacementsPayload.self, from: jsonData)
                processEmbeddedMessages(response.placements[0].embeddedMessages)
            } catch {
                print("Error reading JSON: \(error)")
            }
        }

    }
    
    func loadEmbeededMessagesJSON() -> Data? {
        if let path = Bundle.main.path(forResource: "embeddedmessages", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                return data
            } catch {
                print("Error reading JSON file: \(error)")
            }
        }
        return nil
    }
    
    func loadEmeddedMessages() {
        IterableAPI.embeddedManager.syncMessages {
            DispatchQueue.main.async { [self] in
                self.processEmbeddedMessages(IterableAPI.embeddedManager.getMessages())
            }
        }
    }
    
    func processEmbeddedMessages(_ messages: [IterableEmbeddedMessage]) {
        guard !messages.isEmpty else {
            // Handle the case where messages array is empty
            return
        }
        // getMessages fetch embedded messages as shown in embeddedmessages.json response
        let bannerView = messages[0]
        // We consider rest of messages as carousel of cardviews
        cardViews = Array(messages[1..<messages.count])
        loadBannerView(bannerView)
        embeddedBannerView.isHidden = false
        carouselCollectionView.reloadData()
    }
    
    func loadCardView(_ embeddedView: IterableEmbeddedView, _ embeddedMessage: IterableEmbeddedMessage) {
        embeddedView.primaryBtn.isRoundedSides = true
        embeddedView.secondaryBtn.isRoundedSides = true
        // We are setting the width of buttons as 140 as per our embedded messages width. You can change as per your need
        embeddedView.primaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        embeddedView.secondaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        let config = IterableEmbeddedViewConfig(borderCornerRadius: 10)
        embeddedView.configure(message: embeddedMessage, viewType: .card, config: config)
    }
    
    func loadBannerView(_ embeddedMessage: IterableEmbeddedMessage) {
        let config = IterableEmbeddedViewConfig(borderCornerRadius: 10)
        let embeddedView = IterableEmbeddedView(message: embeddedMessage, viewType: .banner, config: config)
        embeddedView.primaryBtn.isRoundedSides = true
        embeddedView.secondaryBtn.isRoundedSides = true
        // We are setting the width of buttons as 140 as per our embedded messages width. You can change as per your need
        embeddedView.primaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        embeddedView.secondaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        
        // You must initialize frame here for the embeddedView
        embeddedView.frame = CGRect(x: 0, y: 0, width: embeddedBannerView.frame.width, height: embeddedBannerView.frame.height)
        embeddedBannerView.addSubview(embeddedView)
    }
    
    @IBAction func doneButtonTapped(_: UIButton) {
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func syncButtonTapped(_: UIButton) {
        loadEmeddedMessages()
    }
    
    func openUrl(_ url: String?) {
        if let urlString = url, // Replace with your URL string
           let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.open(url)
            }
        }
    }
}

extension EmbeddedMessagesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return cardViews.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: "IterableEmbeddedCardViewCell", for: indexPath) as! IterableEmbeddedCardViewCell
        let cardView = cardViews[indexPath.row]
        loadCardView(cell.embeddedCardView, cardView)
        return cell
    }
    
        
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 350,
                      height: 400)
    }
}

