//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

/// Use this protocol to override the default inbox display behavior
@objc public protocol IterableInboxViewControllerViewDelegate: AnyObject {
    /// View delegate must have a public `required` initializer.
    @objc init()
    
    /// Use this method to override the default display for message creation time. Return nil if you don't want to display time.
    /// - parameter forMessage: IterableInboxMessage
    /// - returns: The string value to display or nil to not display date
    @objc optional func displayDate(forMessage message: IterableInAppMessage) -> String?
    
    /// Use this method to render any additional custom fields other than title, subtitle and createAt.
    /// - parameter forCell: The table view cell to render
    /// - parameter withMessage: IterableInAppMessage
    @objc optional func renderAdditionalFields(forCell cell: IterableInboxCell, withMessage message: IterableInAppMessage)
    
    /// Use this property only when you  have more than one type of custom table view cells.
    /// For example, if you have inbox cells of one type to show  informational mesages,
    /// and inbox cells of another type to show discount messages.
    /// - returns: a list of custom nib names.
    @objc optional var customNibNames: [String]? { get }
    
    /// This function goes hand in hand with `customNibNames` property..
    /// - parameter for: Iterable in app message.
    /// - returns: Name of custom cell for the message or nil if using default cell.
    @objc optional func customNibName(for message: IterableInAppMessage) -> String?
}

@IBDesignable
open class IterableInboxViewController: UITableViewController {
    public enum InboxMode {
        case popup
        case nav
    }
    
    // MARK: Settable properties
    
    /// If you want to use a custom layout for your inbox TableViewCell
    /// this is the variable you should override. Please note that this assumes
    /// that the nib is present in the main bundle.
    @IBInspectable public var cellNibName: String? = nil
    
    /// Set this to `true` to show a popup when an inbox message is selected in the list.
    /// Set this to `false`to push inbox message into navigation stack.
    @IBInspectable public var isPopup: Bool = true {
        didSet {
            if isPopup {
                inboxMode = .popup
            } else {
                inboxMode = .nav
            }
        }
    }
    
    /// Set this property to override default inbox display behavior. You should set either this property
    /// or `viewDelegateClassName`property but not both.
    public weak var viewDelegate: IterableInboxViewControllerViewDelegate?
    
    /// Set this property if you want to set the class name in Storyboard and want `IterableInboxViewController` to create a
    /// view delegate class for you.
    /// The class name must include the package name as well, e.g., MyModule.CustomInboxViewDelegate
    @IBInspectable public var viewDelegateClassName: String? {
        didSet {
            guard let viewDelegateClassName = viewDelegateClassName else {
                return
            }
            instantiateViewDelegate(withClassName: viewDelegateClassName)
        }
    }
    
    /// You can override these insertion/deletion animations for custom ones
    public var insertionAnimation = UITableView.RowAnimation.automatic
    public var deletionAnimation = UITableView.RowAnimation.automatic
    
    // MARK: Initializers
    
    public override init(style: UITableView.Style) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(style: style)
        viewModel.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(coder: aDecoder)
        viewModel.delegate = self
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        viewModel.delegate = self
    }
    
    open override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.attributedTitle = NSAttributedString(string: "Fetching new in-app messages")
            refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
        
        cellLoader = CellLoader(viewDelegate: viewDelegate, cellNibName: cellNibName)
        cellLoader.registerCells(forTableView: tableView)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        ITBInfo()
        super.viewWillAppear(animated)
        
        // Set footer view so that we don't see table view separators
        // for the empty rows.
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = UIView()
        }
        
        if navigationController == nil {
            viewModel.viewWillAppear()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        ITBInfo()
        super.viewWillDisappear(animated)
        
        if navigationController == nil {
            viewModel.viewWillDisappear()
        }
    }
    
    // MARK: - UITableViewDataSource (Required Functions)
    
    open override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.numMessages
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.message(atRow: indexPath.row)
        let cell = cellLoader.loadCell(for: message.iterableMessage, forTableView: tableView, atIndexPath: indexPath)
        
        configure(cell: cell, forMessage: message)
        
        return cell
    }
    
    // MARK: - UITableViewDataSource (Optional Functions)
    
    open override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
    
    open override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }
    
    open override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.remove(atRow: indexPath.row)
        }
    }
    
    // MARK: - UITableViewDelegate (Optional Functions)
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if inboxMode == .popup {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let message = viewModel.message(atRow: indexPath.row)
        
        if let viewController = viewModel.createInboxMessageViewController(for: message, withInboxMode: inboxMode) {
            viewModel.set(read: true, forMessage: message)
            if inboxMode == .nav {
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                if #available(iOS 13.0, *) {
                    viewController.modalPresentationStyle = .overCurrentContext
                } else {
                    viewController.modalPresentationStyle = .overFullScreen
                }
                present(viewController, animated: true)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate (Optional Functions)
    
    open override func scrollViewDidScroll(_: UIScrollView) {
        ITBDebug()
        viewModel.visibleRowsChanged()
    }
    
    // MARK: - IterableInboxViewController-specific Functions and Variables
    
    var viewModel: InboxViewControllerViewModelProtocol
    
    /// Set this mode to `popup` to show a popup when an inbox message is selected in the list.
    /// Set this mode to `nav` to push inbox message into navigation stack.
    private var inboxMode = InboxMode.popup
    
    // we need this variable because we are instantiating the delegate class
    private var strongViewDelegate: IterableInboxViewControllerViewDelegate?
    
    private var cellLoader: CellLoader!
    
    deinit {
        ITBInfo()
    }
    
    @available(iOS 10.0, *)
    @objc private func handleRefreshControl() {
        ITBInfo()
        
        _ = viewModel.refresh()
        
        tableView.refreshControl?.endRefreshing()
    }
    
    private func configure(cell: IterableInboxCell, forMessage message: InboxMessageViewModel) {
        IterableInboxViewController.set(value: message.title, forLabel: cell.titleLbl)
        IterableInboxViewController.set(value: message.subtitle, forLabel: cell.subtitleLbl)
        
        setCreatedAt(cell: cell, message: message)
        
        // unread circle view
        cell.unreadCircleView?.isHidden = message.read
        
        loadCellImage(cell: cell, message: message)
        
        // call the delegate to set additional fields
        viewDelegate?.renderAdditionalFields?(forCell: cell, withMessage: message.iterableMessage)
    }
    
    private func setCreatedAt(cell: IterableInboxCell, message: InboxMessageViewModel) {
        let value: String?
        if let modifier = viewDelegate?.displayDate(forMessage:) {
            value = modifier(message.iterableMessage)
        } else {
            value = IterableInboxViewController.defaultValueToDisplay(forCreatedAt: message.iterableMessage.createdAt)
        }
        IterableInboxViewController.set(value: value, forLabel: cell.createdAtLbl)
    }
    
    private func loadCellImage(cell: IterableInboxCell, message: InboxMessageViewModel) {
        cell.iconImageView?.clipsToBounds = true
        
        if message.hasValidImageUrl() {
            cell.iconContainerView?.isHidden = false
            cell.iconImageView?.isHidden = false
            
            if let data = message.imageData {
                cell.iconImageView?.backgroundColor = nil
                cell.iconImageView?.image = UIImage(data: data)
            } else {
                cell.iconImageView?.backgroundColor = UIColor(hex: "EEEEEE") // loading image
                cell.iconImageView?.image = nil
            }
        } else {
            cell.iconContainerView?.isHidden = true
            cell.iconImageView?.isHidden = true
        }
    }
    
    // if value is present it is set, otherwise hide the label
    private static func set(value: String?, forLabel label: UILabel?) {
        if let value = value {
            label?.isHidden = false
            label?.text = value
        } else {
            label?.isHidden = true
            label?.text = nil
        }
    }
    
    // By default show locale specific medium date
    private static func defaultValueToDisplay(forCreatedAt createdAt: Date?) -> String? {
        guard let createdAt = createdAt else {
            return nil
        }
        return DateFormatter.localizedString(from: createdAt, dateStyle: .medium, timeStyle: .short)
    }
    
    private func instantiateViewDelegate(withClassName className: String) {
        guard className.split(separator: ".").count > 1 else {
            assertionFailure("Module name is missing. 'viewDelegateClassName' must be of the form $package_name.$class_name")
            return
        }
        guard let delegateClass = NSClassFromString(className) as? IterableInboxViewControllerViewDelegate.Type else {
            // we can't use IterableLog here because this happens from storyboard before logging is initialized.
            assertionFailure("Could not initialize dynamic class: \(className), please check module name and protocol \(IterableInboxViewControllerViewDelegate.self) conformanace.")
            return
        }
        
        let delegateObject = delegateClass.init()
        
        strongViewDelegate = delegateObject
        viewDelegate = strongViewDelegate
    }
}

extension IterableInboxViewController: InboxViewControllerViewModelDelegate {
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>]) {
        ITBInfo()
        
        guard Thread.isMainThread else {
            ITBError("\(#function) must be called from main thread")
            return
        }
        
        updateTableView(diff: diff)
        updateUnreadBadgeCount()
    }
    
    func onImageLoaded(forRow row: Int) {
        ITBInfo()
        
        guard Thread.isMainThread else {
            ITBError("\(#function) must be called from main thread")
            return
        }
        
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    var currentlyVisibleRowIndices: [Int] {
        return tableView.indexPathsForVisibleRows?.compactMap(isRowVisible(atIndexPath:)) ?? []
    }
    
    private func updateUnreadBadgeCount() {
        let unreadCount = viewModel.unreadCount
        let badgeValue = unreadCount == 0 ? nil : "\(unreadCount)"
        navigationController?.tabBarItem?.badgeValue = badgeValue
    }
    
    private func updateTableView(diff: [SectionedDiffStep<Int, InboxMessageViewModel>]) {
        tableView.beginUpdates()
        viewModel.beganUpdates()
        
        for result in diff {
            switch result {
            case let .delete(section, row, _): tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: deletionAnimation)
            case let .insert(section, row, _): tableView.insertRows(at: [IndexPath(row: row, section: section)], with: insertionAnimation)
            case let .sectionDelete(section, _): tableView.deleteSections(IndexSet(integer: section), with: deletionAnimation)
            case let .sectionInsert(section, _): tableView.insertSections(IndexSet(integer: section), with: insertionAnimation)
            }
        }
        
        tableView.endUpdates()
        viewModel.endedUpdates()
    }
    
    private func isRowVisible(atIndexPath indexPath: IndexPath) -> Int? {
        let topMargin = CGFloat(10.0)
        let bottomMargin = CGFloat(10.0)
        let frame = tableView.frame
        let statusHeight = UIApplication.shared.statusBarFrame.height
        let navHeight = navigationController?.navigationBar.frame.height ?? 0
        let topHeightToSubtract = statusHeight + navHeight - topMargin // subtract topMargin
        
        let tabBarHeight = tabBarController?.tabBar.bounds.height ?? 0
        let bottomHeightToSubtract = tabBarHeight - bottomMargin
        let size = CGSize(width: frame.width, height: frame.height - (topHeightToSubtract + bottomHeightToSubtract))
        
        let newRect = CGRect(origin: CGPoint(x: frame.origin.x, y: frame.origin.y + topHeightToSubtract), size: size)
        
        let cellRect = tableView.rectForRow(at: indexPath)
        let convertedRect = tableView.convert(cellRect, to: tableView.superview)
        return newRect.contains(convertedRect) ? indexPath.row : nil
    }
}

private struct CellLoader {
    weak var viewDelegate: IterableInboxViewControllerViewDelegate?
    let cellNibName: String?
    
    init(viewDelegate: IterableInboxViewControllerViewDelegate?,
         cellNibName: String?) {
        self.viewDelegate = viewDelegate
        self.cellNibName = cellNibName
    }
    
    func registerCells(forTableView tableView: UITableView) {
        registerDefaultCell(forTableView: tableView)
        registerCustomCells(forTableView: tableView)
    }
    
    func loadCell(for message: IterableInAppMessage, forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> IterableInboxCell {
        guard let viewDelegate = viewDelegate else {
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        guard let modifier1 = viewDelegate.customNibNames, let customNibNames = modifier1, customNibNames.count > 0 else {
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        guard let modifier2 = viewDelegate.customNibName(for:), let customNibName = modifier2(message) else {
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: customNibName, for: indexPath) as? IterableInboxCell else {
            ITBError("Please make sure that an the nib: \(customNibName) is present in the main bundle")
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    private let iterableCellNibName = "IterableInboxCell"
    private let defaultCellReuseIdentifier = "inboxCell"
    
    private func registerCustomCells(forTableView tableView: UITableView) {
        guard let viewDelegate = viewDelegate else {
            return
        }
        guard let modifier = viewDelegate.customNibNames, let customNibNames = modifier, customNibNames.count > 0 else {
            return
        }
        
        customNibNames.forEach { customNibName in
            let nib = UINib(nibName: customNibName, bundle: Bundle.main)
            tableView.register(nib, forCellReuseIdentifier: customNibName)
        }
    }
    
    private func registerDefaultCell(forTableView tableView: UITableView) {
        if let cellNibName = self.cellNibName {
            if CellLoader.nibExists(inBundle: Bundle.main, withNibName: cellNibName) {
                let nib = UINib(nibName: cellNibName, bundle: Bundle.main)
                tableView.register(nib, forCellReuseIdentifier: defaultCellReuseIdentifier)
            } else {
                fatalError("Cannot find nib: \(cellNibName) in main bundle.")
            }
        } else {
            let bundle = Bundle(for: IterableInboxViewController.self)
            if CellLoader.nibExists(inBundle: bundle, withNibName: iterableCellNibName) {
                let nib = UINib(nibName: iterableCellNibName, bundle: bundle)
                tableView.register(nib, forCellReuseIdentifier: defaultCellReuseIdentifier)
            } else {
                tableView.register(IterableInboxCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
            }
        }
    }
    
    private static func nibExists(inBundle bundle: Bundle, withNibName nibName: String) -> Bool {
        guard let path = bundle.path(forResource: nibName, ofType: "nib") else {
            return false
        }
        
        return FileManager.default.fileExists(atPath: path)
    }
    
    private func loadDefaultCell(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> IterableInboxCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath) as? IterableInboxCell else {
            fatalError("Please make sure that an the nib: \(cellNibName ?? iterableCellNibName) is present in the main bundle")
        }
        return cell
    }
}
