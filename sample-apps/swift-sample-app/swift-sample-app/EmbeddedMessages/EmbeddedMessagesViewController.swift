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
    @IBOutlet weak var embeddedBannerView: IterableEmbeddedView!
    @IBOutlet weak var carouselCollectionView: UICollectionView!
    var cardViews: [ResolvedMessage] = []
    
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
        
        // getMessages fetch embedded messages as shown in embeddedmessages.json response
        IterableAPI.embeddedManager.resolveMessages(messages) { [self] resolvedMessages in
            // Handle the resolved messages here
            // The resolvedMessages array contains the results
            if (resolvedMessages.count > 0) {
                // We get one placement only from which we will consider 1st message as banner
                let bannerView = resolvedMessages[0]
                // We consider rest of messages as carousel of cardviews
                cardViews = Array(resolvedMessages[1..<resolvedMessages.count])
                loadBannerView(bannerView)
                embeddedBannerView.isHidden = false
                carouselCollectionView.reloadData()
            }
        }
        
    }
    
    func loadCardView(_ embeddedView: IterableEmbeddedView, _ embeddedMessage: ResolvedMessage) {
        DispatchQueue.main.async { [self] in
            loadEmbeddedView(embeddedView, embeddedMessage: embeddedMessage, type: IterableEmbeddedViewType.card)
        }
        
    }
    
    func loadBannerView(_ embeddedMessage: ResolvedMessage) {
        DispatchQueue.main.async { [self] in
            loadEmbeddedView(embeddedBannerView, embeddedMessage: embeddedMessage, type: IterableEmbeddedViewType.banner)
        }
        
    }
    
    func loadEmbeddedView(_ embeddedView: IterableEmbeddedView, embeddedMessage: ResolvedMessage, type: IterableEmbeddedViewType) {
        
        embeddedView.iterableEmbeddedViewDelegate = self
        embeddedView.primaryBtn.isRoundedSides = true
        embeddedView.secondaryBtn.isRoundedSides = true
        // We are setting the width of buttons as 140 as per our embedded messages width. You can change as per your need
        embeddedView.primaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        embeddedView.secondaryBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        embeddedView.labelTitle.text = embeddedMessage.title
        embeddedView.labelDescription.text = embeddedMessage.description
        embeddedView.EMimage = embeddedMessage.image
        embeddedView.EMbuttonText = embeddedMessage.buttonText
        embeddedView.EMbuttonTwoText = embeddedMessage.buttonTwoText
        embeddedView.message = embeddedMessage.message

        let config = IterableEmbeddedViewConfig(borderCornerRadius: 10)
        // You must call this method which sets the type for this view which helps render the particular layout of cardview/bannerview
        embeddedView.configure(viewType: type, config: config)
        
        
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

extension EmbeddedMessagesViewController: IterableEmbeddedViewDelegate {
    func didPressPrimaryButton(button: UIButton, viewTag: Int, message: IterableSDK.IterableEmbeddedMessage?) {
        let buttonData =  message?.elements?.buttons?.first
        let url = buttonData?.action?.data
        openUrl(url)
    }
    
    func didPressSecondaryButton(button: UIButton, viewTag: Int, message: IterableSDK.IterableEmbeddedMessage?) {
        let buttonData =  message?.elements?.buttons?[1]
        let url = buttonData?.action?.data
        openUrl(url)
    }
    
    func didPressBanner(banner: IterableSDK.IterableEmbeddedView, viewTag: Int, message: IterableSDK.IterableEmbeddedMessage?) {
        openUrl(message?.elements?.defaultAction?.data)
    }
}

extension EmbeddedMessagesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return cardViews.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: "IterableEmbeddedCardViewCell", for: indexPath) as? IterableEmbeddedCardViewCell else {
            return UICollectionViewCell()
        }
        if indexPath.row < cardViews.count {
            let cardView = cardViews[indexPath.row]
            loadCardView(cell.embeddedCardView, cardView)
        }
            
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 350,
                      height: 400)
    }
}

