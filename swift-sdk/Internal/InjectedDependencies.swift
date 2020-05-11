//
//  Created by Tapash Majumder on 3/9/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import WebKit

/// This class is meant to be used ony for dependencies which can't be set in the constructor.
/// In case of subclasses of UIViewController etc we don't always have access to the initialization.
/// Also note that these are global so it may impact parallel tests.
/// Tests that use these variables should not be parallelized.
struct InjectedDependencies {
    enum Key: String {
        case iOS13Available
    }
    
    static var shared = InjectedDependencies()
    
    mutating func set<T>(for name: Key? = nil, factory: @escaping () -> T) {
        let typeName = String(describing: T.self)
        if let name = name {
            factories["\(typeName).\(name.rawValue)"] = factory
            factories["Optional<\(typeName)>.\(name.rawValue)"] = factory
        } else {
            factories[typeName] = factory
            factories["Optional<\(typeName)>"] = factory
        }
    }
    
    func resolve<T>(name: Key?) -> T {
        var typeName = String(describing: T.self)
        if let name = name {
            typeName = "\(typeName).\(name.rawValue)"
        }
        return factories[typeName]!() as! T
    }
    
    private var factories = [String: () -> Any]()
    
    private init() {}
}

/// Use this property wrapper annotation for global injected dependencies.
/// Note that this should be used only when constructor initialization is not available.
@propertyWrapper
struct Inject<Value> {
    var wrappedValue: Value {
        return InjectedDependencies.shared.resolve(name: name)
    }
    
    init(name: InjectedDependencies.Key?) {
        self.name = name
    }
    
    init() {
        name = nil
    }
    
    private var name: InjectedDependencies.Key?
}

protocol ViewCalculationsProtocol {
    func width(for view: UIView) -> CGFloat
    func height(for view: UIView) -> CGFloat
    func center(for view: UIView) -> CGPoint
    func safeAreaInsets(for view: UIView) -> UIEdgeInsets
}

extension ViewCalculationsProtocol {
    func width(for view: UIView) -> CGFloat {
        view.bounds.width
    }
    
    func height(for view: UIView) -> CGFloat {
        view.bounds.height
    }
    
    func center(for view: UIView) -> CGPoint {
        view.center
    }
    
    func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
        if #available(iOS 11, *) {
            return view.safeAreaInsets
        } else {
            return .zero
        }
    }
}

struct ViewPosition: Equatable {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var center: CGPoint = CGPoint.zero
}

protocol WebViewProtocol {
    var view: UIView { get }
    @discardableResult func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation?
    func set(position: ViewPosition)
    func set(navigationDelegate: WKNavigationDelegate?)
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
    func layoutSubviews()
    func calculateHeight() -> Future<CGFloat, IterableError>
}

extension WKWebView: WebViewProtocol {
    var view: UIView {
        self
    }
    
    func set(position: ViewPosition) {
        frame.size.width = position.width
        frame.size.height = position.height
        center = position.center
    }
    
    func set(navigationDelegate: WKNavigationDelegate?) {
        self.navigationDelegate = navigationDelegate
    }
    
    func calculateHeight() -> Future<CGFloat, IterableError> {
        let promise = Promise<CGFloat, IterableError>()
        
        evaluateJavaScript("document.body.offsetHeight", completionHandler: { height, _ in
            guard let floatHeight = height as? CGFloat, floatHeight >= 20 else {
                ITBError("unable to get height")
                promise.reject(with: IterableError.general(description: "unable to get height"))
                return
            }
            
            promise.resolve(with: floatHeight)
        })
        
        return promise
    }
}

protocol InjectedDependencyModuleProtocol {
    var viewCalculations: ViewCalculationsProtocol { get }
    var webView: WebViewProtocol { get }
}

struct InjectedDependencyModule: InjectedDependencyModuleProtocol {
    let viewCalculations: ViewCalculationsProtocol = ViewCalculations()
    
    var webView: WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
}

struct ViewCalculations: ViewCalculationsProtocol {}
