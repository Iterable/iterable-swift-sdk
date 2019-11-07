//
//  Created by Tapash Majumder on 4/30/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@IBDesignable
open class IterableInboxNavigationViewController: UINavigationController {
    // MARK: Settable properties
    
    /// If you want to use a custom layout for your Inbox TableViewCell
    /// this is where you should override it. Please note that this assumes
    /// that the xib is present in the main bundle.
    @IBInspectable public var cellNibName: String? = nil {
        didSet {
            inboxViewController?.cellNibName = cellNibName
        }
    }
    
    /// This is the title for the Inbox Navigation Bar
    @IBInspectable public var navTitle: String? = nil {
        didSet {
            if let navTitle = navTitle {
                inboxViewController?.navigationItem.title = navTitle
            }
        }
    }
    
    @IBInspectable public var isPopup: Bool = true {
        didSet {
            if isPopup {
                inboxViewController?.inboxMode = .popup
            } else {
                inboxViewController?.inboxMode = .nav
            }
        }
    }
    
    /// Set this property if you want to set the view delegate class name in Storyboard
    /// and want `IterableInboxViewController` to create a view delegate class for you.
    @IBInspectable public var viewDelegateClassName: String? = nil {
        didSet {
            inboxViewController?.viewDelegateClassName = viewDelegateClassName
        }
    }
    
    // MARK: Initializers
    
    /// This initializer should be used when initializing from Code.
    public init() {
        ITBInfo()
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    /// This initializer will be called when initializing from storyboard
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        // Add "Done" button if this view is being presented by another view controller
        // We have to do the following asynchronously because
        // self.presentingViewController is not set yet.
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, strongSelf.viewControllers.count > 0 else {
                return
            }
            if let _ = strongSelf.presentingViewController {
                let viewController = strongSelf.viewControllers[0]
                if viewController.navigationItem.leftBarButtonItem == nil, viewController.navigationItem.rightBarButtonItem == nil {
                    viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(strongSelf.onDoneTapped))
                }
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        ITBInfo()
        super.viewWillAppear(animated)
        
        inboxViewController?.viewModel.viewWillAppear()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        ITBInfo()
        super.viewWillDisappear(animated)
        
        inboxViewController?.viewModel.viewWillDisappear()
    }
    
    /// Do not use this
    private override init(rootViewController: UIViewController) {
        ITBInfo()
        super.init(rootViewController: rootViewController)
        setup()
    }
    
    /// Do not use this
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    private func setup() {
        let inboxViewController: IterableInboxViewController
        if viewControllers.count > 0 {
            // Means this view controller was initialized in code and we have set
            // the rootViewController.
            guard let viewController = viewControllers[0] as? IterableInboxViewController else {
                assertionFailure("RootViewController must be of type IterableInboxViewController")
                return
            }
            inboxViewController = viewController
        } else {
            inboxViewController = IterableInboxViewController(style: .plain)
            viewControllers.append(inboxViewController)
        }
        
        inboxViewController.cellNibName = cellNibName
    }
    
    @objc private func onDoneTapped() {
        ITBInfo()
        presentingViewController?.dismiss(animated: true)
    }
    
    private var inboxViewController: IterableInboxViewController? {
        return viewControllers[0] as? IterableInboxViewController
    }
}
