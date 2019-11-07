//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

/// Use this protocol to override the default inbox display behavior
@objc public protocol IterableInboxViewControllerViewDelegate: AnyObject {
    /// Use this method to override the default display for message creation time. Return nil if you don't want to display time.
    /// - parameter forMessage: IterableInboxMessage
    /// - returns: The string value to display or nil to not display date
    @objc optional func displayDate(forMessage message: IterableInAppMessage) -> String?
    
    /// Use this method to render any additional custom fields other than title, subtitle and createAt.
    /// - parameter forCell: The table view cell to render
    /// - parameter withMessage: IterableInAppMessage
    @objc optional func renderAdditionalFields(forCell cell: IterableInboxCell, withMessage message: IterableInAppMessage)
    
    /// Implement this method if you want `IterableInboxViewController` to create an instance of the view delegate class
    /// This method is used when `viewDelegateClassName` property is set.
    @objc optional static func createInstance() -> IterableInboxViewControllerViewDelegate
}

@IBDesignable
open class IterableInboxViewController: UITableViewController {
    public enum InboxMode {
        case popup
        case nav
    }
    
    // MARK: Settable properties
    
    /// Set this property to override default inbox display behavior. You should set either this property
    /// or `viewDelegateClassName`property but not both.
    public weak var viewDelegate: IterableInboxViewControllerViewDelegate?
    
    /// Set this property if you want to set the class name in Storyboard and want `IterableInboxViewController` to create a
    /// view delegate class for you.
    @IBInspectable public var viewDelegateClassName: String? {
        didSet {
            guard let viewDelegateClassName = viewDelegateClassName else {
                return
            }
            instantiateViewDelegate(withClassName: viewDelegateClassName)
        }
    }
    
    /// If you want to use a custom layout for your inbox TableViewCell
    /// this is the variable you should override. Please note that this assumes
    /// that the XIB is present in the main bundle.
    @IBInspectable public var cellNibName: String? = nil
    
    /// Set this mode to `popup` to show a popup when an inbox message is selected in the list.
    /// Set this mode to `nav` to push inbox message into navigation stack.
    public var inboxMode = InboxMode.popup
    
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
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching new in-app messages")
        refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        registerTableViewCell()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as? IterableInboxCell else {
            fatalError("Please make sure that an the nib: \(cellNibName!) is present in the main bundle")
        }
        
        configure(cell: cell, forMessage: viewModel.message(atRow: indexPath.row))
        
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
    
    private let iterableCellNibName = "IterableInboxCell"
    
    // we need this variable because we are instantiating the delegate class
    private var strongViewDelegate: IterableInboxViewControllerViewDelegate?
    
    deinit {
        ITBInfo()
    }
    
    private func registerTableViewCell() {
        let cellNibName = self.cellNibName ?? iterableCellNibName
        let bundle = self.cellNibName == nil ? Bundle(for: IterableInboxViewController.self) : Bundle.main
        
        let nib = UINib(nibName: cellNibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: "inboxCell")
    }
    
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
        guard let delegateClass = NSClassFromString(className) as? IterableInboxViewControllerViewDelegate.Type else {
            // we can't use IterableLog here because this happens from storyboard before logging is initialized.
            print("❤️: Could not initialize dynamic class: \(className), please check protocol \(IterableInboxViewControllerViewDelegate.self) conformanace.")
            return
        }
        guard let delegateObject = delegateClass.createInstance?() else {
            print("❤️: 'createInstance()' method is not defined in '\(className)'")
            return
        }
        
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
