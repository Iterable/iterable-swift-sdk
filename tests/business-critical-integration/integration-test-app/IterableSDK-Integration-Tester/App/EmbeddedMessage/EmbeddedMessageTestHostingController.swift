//
//  EmbeddedMessageTestHostingController.swift
//  IterableSDK-Integration-Tester
//

import UIKit
import SwiftUI

final class EmbeddedMessageTestHostingController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create SwiftUI view
        let embeddedTestView = EmbeddedMessageTestView()
        let hostingController = UIHostingController(rootView: embeddedTestView)
        
        // Add hosting controller as child
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}

