import Foundation
import SwiftUI

import IterableSDK

enum SelectedTab {
    case home
    case inbox
}

class AppModel: ObservableObject {
    static let shared = AppModel()
    
    @Published
    var selectedTab: SelectedTab?
    
    @Published
    var selectedCoffee: Coffee? {
        didSet {
            selectedTab = .home
        }
    }

    @Published
    var email: String? = IterableAPI.email
}
