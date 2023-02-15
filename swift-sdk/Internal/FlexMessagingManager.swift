//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

class FlexMessagingManager: IterableFlexMessagingManagerProtocol {
    init() {
        ITBInfo()
        
//        let json = JSONSerialization.jsonObject(with:
//        """
//        [
//            {
//                "metadata": {
//                    "id": "jub9845-3948jviu-934rouifjfj",
//                    "placementId": "vf93-34rf-7hfei"
//                    "campaignId": "903f-59bjg-3eijv",
//                    "isProof": false
//                },
//
//                "elements": {
//                    "type": "custom",
//                    "buttons": [
//                        {"id": "reward-button", "title": "Get Reward", "action": "success"},
//                        {"id": "dismiss-button", "title": "Dismiss", "action": "dismiss"}
//                    ],
//                    "images": [
//                        {"id": "image-background", "url": "https://example-image-url.com/first-image"},
//                        {"id": "image-reward-button", "url": "https://example-image-url.com/second-image"},
//                        {"id": "image-dismiss-button", "url": "https://example-image-url.com/third-image"},
//                    ],
//                    "text": [
//                        {"id": "title", "text": "TITLE!!"},
//                        {"id": "body", "text": "lots of words here"}
//                    ]
//                },
//
//                "payload": {
//                    "key or other valid JSON key": "any valid JSON value goes here, not just a string",
//                    "numbers": [1, 2, 3]
//                }
//            }
//        ]
//        """.data(using: .utf8) ?? Data())
        
        let messages = [IterableFlexMessage(id: "jub9845-3948jviu-934rouifjfj",
                                            placementId: "vf93-34rf-7hfei",
                                            campaignId: "903f-59bjg-3eijv",
                                            isProof: false)]
        
        print("flex \(messages)")
        
        let encodedMessages = FlexMessagingSerialization.serialize(messages: messages)
        
        print("flex \(encodedMessages)")
        
        let payloadResponse = FlexMessagingSerialization.decode(messages: encodedMessages)
        
        print("native data type \(payloadResponse)")
    }
    
    deinit {
        ITBInfo()
    }
    
    func getMessages(placementId: String) -> [IterableFlexMessage] {
        return messages.filter({ $0.metadata.placementId == placementId })
    }
    
    private var messages: [IterableFlexMessage] = []
}
