//
//  InAppMessageTestHostingController.swift
//  IterableSDK-Integration-Tester
//

import UIKit
import SwiftUI

/// UIKit hosting controller for the SwiftUI InAppMessageTestView
/// This allows easy integration with existing UIKit navigation
class InAppMessageTestHostingController: UIHostingController<InAppMessageTestView> {
    
    init() {
        super.init(rootView: InAppMessageTestView())
        self.title = "In-App Messages"
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure navigation bar appearance if needed
        navigationItem.largeTitleDisplayMode = .never
    }
}

