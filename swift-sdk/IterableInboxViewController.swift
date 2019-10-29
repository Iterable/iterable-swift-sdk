//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

/// Use this protocol to override the default inbox display behavior
@objc public protocol IterableInboxViewControllerDelegate: AnyObject {
    /// Override the title to display instead of actual inbox message title
    /// - parameter forTitle: The actual title of inbox message
    /// - returns: The title to display or nil to not display title
    @objc optional func display(forTitle title: String?) -> String?
    
    /// Override the title to display instead of actual inbox message subtitle
    /// - parameter forSubtitle: The actual subtitle of inbox message
    /// - returns: The title to display or nil to not display subtitle
    @objc optional func display(forSubtitle subtitle: String?) -> String?
    
    /// Override the title to display instead of actual inbox message title
    /// - parameter forDate: The actual creation time of inbox message
    /// - returns: The string value to display or nil to not display date
    @objc optional func display(forDate date: Date?) -> String?
}

@IBDesignable
open class IterableInboxViewController: UITableViewController {
    public enum InboxMode {
        case popup
        case nav
    }
    
    // MARK: Settable properties
    
    /// Set this property to override default inbox display behavior
    public weak var delegate: IterableInboxViewControllerDelegate?
    
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
        
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.attributedTitle = NSAttributedString(string: "Fetching new in-app messages")
            refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
        
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
                definesPresentationContext = true
                viewController.modalPresentationStyle = .overCurrentContext
                if let rootViewController = IterableUtil.rootViewController {
                    rootViewController.present(viewController, animated: true)
                } else {
                    present(viewController, animated: true)
                }
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
    
    deinit {
        ITBInfo()
    }
    
    private func registerTableViewCell() {
        let cellNibName = self.cellNibName ?? iterableCellNibName
        let bundle = self.cellNibName == nil ? Bundle(for: IterableInboxViewController.self) : Bundle.main
        
        let nib = UINib(nibName: cellNibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: "inboxCell")
    }
    
    @available(iOS 10.0, *)
    @objc private func handleRefreshControl() {
        ITBInfo()
        
        _ = viewModel.refresh()
        
        tableView.refreshControl?.endRefreshing()
    }
    
    private func configure(cell: IterableInboxCell, forMessage message: InboxMessageViewModel) {
        setTitle(cell: cell, message: message)
        setSubtitle(cell: cell, message: message)
        setCreatedAt(cell: cell, message: message)
        
        // unread circle view
        cell.unreadCircleView?.isHidden = message.read
        
        loadCellImage(cell: cell, message: message)
    }
    
    private func setTitle(cell: IterableInboxCell, message: InboxMessageViewModel) {
        let displayValue = IterableInboxViewController.valueToDisplay(value: message.title,
                                                                      defaultDisplayFromValue: { $0 },
                                                                      modifiedDisplayFromValue: delegate?.display(forTitle:))
        IterableInboxViewController.set(value: displayValue, forLabel: cell.titleLbl)
    }
    
    private func setSubtitle(cell: IterableInboxCell, message: InboxMessageViewModel) {
        let displayValue = IterableInboxViewController.valueToDisplay(value: message.subtitle,
                                                                      defaultDisplayFromValue: { $0 },
                                                                      modifiedDisplayFromValue: delegate?.display(forSubtitle:))
        IterableInboxViewController.set(value: displayValue, forLabel: cell.subtitleLbl)
    }
    
    private func setCreatedAt(cell: IterableInboxCell, message: InboxMessageViewModel) {
        let displayValue = IterableInboxViewController.valueToDisplay(value: message.createdAt,
                                                                      defaultDisplayFromValue: IterableInboxViewController.defaultValueToDisplay(forCreatedAt:),
                                                                      modifiedDisplayFromValue: delegate?.display(forDate:))
        IterableInboxViewController.set(value: displayValue, forLabel: cell.createdAtLbl)
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
    
    private static func valueToDisplay<T>(value: T?, defaultDisplayFromValue: (T?) -> String?, modifiedDisplayFromValue: ((T?) -> String?)?) -> String? {
        if let modifiedDisplayFromValue = modifiedDisplayFromValue {
            return modifiedDisplayFromValue(value)
        } else {
            return defaultDisplayFromValue(value)
        }
    }
    
    // By default show locale specific medium date
    private static func defaultValueToDisplay(forCreatedAt createdAt: Date?) -> String? {
        guard let createdAt = createdAt else {
            return nil
        }
        return DateFormatter.localizedString(from: createdAt, dateStyle: .medium, timeStyle: .short)
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
