//
//  DeeplinkHandler.swift
//  iOS Demo
//
//  Created by Tapash Majumder on 5/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

import IterableSDK

struct DeeplinkHandler {
    static func handle(url: URL) -> Bool {
        if let deeplink = Deeplink.from(url: url) {
            show(deeplink: deeplink)
            return true
        } else {
            return false
        }
    }
    
    private static func show(deeplink: Deeplink) {
        if let coffeeType = deeplink.toCoffeeType() {
            // single coffee
            show(coffee: coffeeType)
        } else {
            // coffee list with query
            if case let .coffee(query) = deeplink {
                showCoffeeList(query: query)
            } else {
                assertionFailure("could not determine coffee type.")
            }
        }
    }
    
    private static func show(coffee: CoffeeType) {
        let coffeeVC = CoffeeViewController.createFromStoryboard()
        coffeeVC.coffee = coffee
        if let rootNav = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController {
            if let coffeeListVC = rootNav.viewControllers[0] as? CoffeeListTableViewController {
                coffeeListVC.searchTerm = nil
            }
            rootNav.popToRootViewController(animated: false)
            rootNav.pushViewController(coffeeVC, animated: true)
        }
    }
    
    private static func showCoffeeList(query: String?) {
        if let rootNav = UIApplication.shared.delegate?.window??.rootViewController as? UINavigationController {
            rootNav.popToRootViewController(animated: true)
            if let coffeeListVC = rootNav.viewControllers[0] as? CoffeeListTableViewController {
                coffeeListVC.searchTerm = query
            }
        }
    }
    
    // This enum helps with parsing of Deeplinks.
    // Given a URL this enum will return a Deeplink.
    // The deep link comes in as http://domain.com/../mocha
    // or http://domain.com/../coffee?q=mo
    private enum Deeplink {
        case mocha
        case latte
        case cappuccino
        case black
        case coffee(q: String?)
        
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
            case "coffee":
                return parseCoffeeList(fromUrl: url)
            default:
                return nil
            }
        }
        
        private static func parseCoffeeList(fromUrl url: URL) -> Deeplink {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return .coffee(q: nil)
            }
            guard let queryItems = components.queryItems else {
                return .coffee(q: nil)
            }
            guard let index = queryItems.firstIndex(where: { $0.name == "q" }) else {
                return .coffee(q: nil)
            }
            
            return .coffee(q: queryItems[index].value)
        }
        
        // converts deep link to coffee
        // return nil if it refers to coffee list
        func toCoffeeType() -> CoffeeType? {
            switch self {
            case .coffee:
                return nil
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
