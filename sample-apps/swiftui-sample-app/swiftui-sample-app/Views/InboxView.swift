import Foundation
import SwiftUI

import IterableSDK

struct InboxView: UIViewControllerRepresentable {
  typealias UIViewControllerType = IterableInboxViewController

  func makeUIViewController(context: Context) -> IterableInboxViewController {
    let inbox = IterableInboxViewController()
    inbox.noMessagesTitle = "No Messages"
    inbox.noMessagesBody = "Please check back later"
    return inbox
  }
  
  func updateUIViewController(_ uiViewController: IterableInboxViewController, context: Context) {
  }
}
