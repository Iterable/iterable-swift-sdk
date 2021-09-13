import Foundation
import SwiftUI

import IterableSDK

class AppModel: ObservableObject {
    static let shared = AppModel()
    
    @Published
    var selectedCoffee: Coffee?

    @Published
    var email: String? = IterableAPI.email
}
