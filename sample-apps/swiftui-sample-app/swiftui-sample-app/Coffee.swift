import Foundation
import SwiftUI

struct Coffee: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var imageName: String
    
    var image: Image {
        Image(imageName)
    }
}

extension Coffee: Equatable {
    static func == (lhs: Coffee, rhs: Coffee) -> Bool {
        lhs.id == rhs.id
    }
}

extension Coffee: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Coffee {
    static let all: [Coffee] = [
        .cappuccino,
        .latte,
        .mocha,
        .black,
    ]
    
    static let cappuccino = Coffee(id: "cap", title: "Cappuccino", description: "Foamy delicious", imageName: "Cappuccino")
    static let latte = Coffee(id: "latte", title: "Latte", description: "Scrumptious", imageName: "Latte")
    static let mocha = Coffee(id: "mocha", title: "Mocha", description: "Mmm... mocha", imageName: "Mocha")
    static let black = Coffee(id: "black", title: "Black", description: "Strong and goog for your health", imageName: "Black")

}
