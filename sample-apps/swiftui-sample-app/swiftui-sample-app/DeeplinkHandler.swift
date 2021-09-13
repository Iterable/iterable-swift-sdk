import Foundation

struct DeepLinkHandler {
    static func handle(url: URL) -> Bool {
        if let deeplink = Deeplink.from(url: url) {
            show(deeplink: deeplink)
            return true
        } else {
            return false
        }
    }
    
    private static func show(deeplink: Deeplink) {
        AppModel.shared.selectedCoffee = deeplink.toCoffee()
    }
    
    // This enum helps with parsing of Deeplinks.
    // Given a URL this enum will return a Deeplink.
    // The deep link comes in as http://domain.com/../mocha
    private enum Deeplink {
        case mocha
        case latte
        case cappuccino
        case black
        
        static func from(url: URL) -> Deeplink? {
            let page = url.lastPathComponent.lowercased()
            switch page {
            case "mocha":
                return .mocha
            case "latte":
                return .latte
            case "cappuccino":
                return .cappuccino
            case "black":
                return .black
            default:
                return nil
            }
        }
        
        // converts deep link to coffee
        func toCoffee() -> Coffee {
            switch self {
            case .black:
                return .black
            case .cappuccino:
                return .cappuccino
            case .latte:
                return .latte
            case .mocha:
                return .mocha
            }
        }
    }
}
