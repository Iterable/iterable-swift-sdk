//
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@IBDesignable
@available(iOSApplicationExtension, unavailable)
open class IterableInboxViewController: UITableViewController {
    public enum InboxMode {
        case popup
        case nav
    }
    
    /// By default, messages are sorted chronologically.
    /// This enumeration has sample comparators that can be used by `IterableInboxViewControllerViewDelegate`.
    /// You can create your own comparators which can be functions or closures
    public enum DefaultComparator {
        /// Descending by `createdAt`
        public static let descending: (IterableInAppMessage, IterableInAppMessage) -> Bool = {
            $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast
        }
        
        /// Ascending by `createdAt`
        public static let ascending: (IterableInAppMessage, IterableInAppMessage) -> Bool = {
            $0.createdAt ?? Date.distantPast < $1.createdAt ?? Date.distantPast
        }
    }
    
    /// Default date mappers that you can use as sample for `IterableInboxViewControllerViewDelegate`.
    public enum DefaultDateMapper {
        /// short date and short time
        public static var localizedShortDateShortTime: (IterableInAppMessage) -> String? = {
            $0.createdAt.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) }
        }
        
        /// This date mapper is used If you do not set `dateMapper` property for `IterableInboxViewControllerViewDelegate`.
        public static var localizedMediumDateShortTime: (IterableInAppMessage) -> String? = {
            $0.createdAt.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short) }
        }
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
    
    /// We default, we don't show any message when inbox is empty.
    /// If you want to show a message, such as, "There are no messages", you will
    /// have to set the `noMessagesTitle` and  `noMessagesText` properties below.

    /// Use this to set the title to show when there are no message in the inbox.
    @IBInspectable public var noMessagesTitle: String? = nil

    /// Use this to set the message to show when there are no message in the inbox.
    @IBInspectable public var noMessagesBody: String? = nil

    
    /// when in popup mode, specify here if you'd like to change the presentation style
    public var popupModalPresentationStyle: UIModalPresentationStyle? = nil
    
    /// Set this property to override default inbox display behavior. You should set either this property
    /// or `viewDelegateClassName`property but not both.
    public var viewDelegate: IterableInboxViewControllerViewDelegate? {
        didSet {
            guard let viewDelegate = self.viewDelegate else {
                return
            }
            viewModel.set(comparator: viewDelegate.comparator,
                          filter: viewDelegate.filter,
                          sectionMapper: viewDelegate.messageToSectionMapper)
        }
    }
    
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
    
    override public init(style: UITableView.Style) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(style: style)
        viewModel.view = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(coder: aDecoder)
        viewModel.view = self
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        viewModel = InboxViewControllerViewModel()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        viewModel.view = self
    }
    
    override open func viewDidLoad() {
        ITBDebug()
        
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
    
    override open func viewWillAppear(_ animated: Bool) {
        ITBDebug()
        
        super.viewWillAppear(animated)
        
        // Set footer view so that we don't see table view separators
        // for the empty rows.
        if tableView.tableFooterView == nil {
            tableView.tableFooterView = UIView()
        }
        
        /// if nav is of type `IterableInboxNavigationViewController` then
        /// `viewWillAppear` will be called from there. Otherwise we have to call it here.
        if !isNavControllerIterableNavController() {
            viewModel.viewWillAppear()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        ITBDebug()
        
        super.viewWillDisappear(animated)
        
        /// if nav is of type `IterableInboxNavigationViewController` then
        /// `viewWillDisappear` will be called from there. Otherwise we have to call it here.
        if !isNavControllerIterableNavController() {
            viewModel.viewWillDisappear()
        }
    }
    
    // MARK: - UITableViewDataSource (Required Functions)
    
    override open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numRows(in: section)
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = viewModel.message(atIndexPath: indexPath)
        let cell = cellLoader.loadCell(for: message.iterableMessage, forTableView: tableView, atIndexPath: indexPath)
        
        configure(cell: cell, forMessage: message)
        
        return cell
    }
    
    // MARK: - UITableViewDataSource (Optional Functions)
    
    override open func numberOfSections(in _: UITableView) -> Int {
        if noMessagesTitle != nil || noMessagesBody != nil {
            if viewModel.isEmpty() {
                tableView.setEmptyView(title: noMessagesTitle, message: noMessagesBody)
            } else {
                tableView.restore()
            }
        }
        return viewModel.numSections
    }
    
    override open func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        true
    }
    
    override open func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.remove(atIndexPath: indexPath)
        }
    }
    
    // MARK: - UITableViewDelegate (Optional Functions)
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if inboxMode == .popup {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let message = viewModel.message(atIndexPath: indexPath)
        
        if let viewController = viewModel.createInboxMessageViewController(for: message, withInboxMode: inboxMode) {
            viewModel.set(read: true, forMessage: message)
            
            if inboxMode == .nav {
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                setModalPresentationStyle(for: viewController)
                
                present(viewController, animated: true)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate (Optional Functions)
    
    override open func scrollViewDidScroll(_: UIScrollView) {
        ITBDebug()
        
        viewModel.visibleRowsChanged()
    }
    
    // MARK: - IterableInboxViewController-specific Functions and Variables
    
    var viewModel: InboxViewControllerViewModelProtocol
    
    /// Set this mode to `popup` to show a popup when an inbox message is selected in the list.
    /// Set this mode to `nav` to push inbox message into navigation stack.
    private var inboxMode = InboxMode.popup
    
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
        let dateMapper = viewDelegate?.dateMapper ?? DefaultDateMapper.localizedMediumDateShortTime
        IterableInboxViewController.set(value: dateMapper(message.iterableMessage), forLabel: cell.createdAtLbl)
    }
    
    private func loadCellImage(cell: IterableInboxCell, message: InboxMessageViewModel) {
        cell.iconImageView?.clipsToBounds = true
        cell.iconImageView?.isAccessibilityElement = true
        
        if message.hasValidImageUrl() {
            cell.iconContainerView?.isHidden = false
            cell.iconImageView?.isHidden = false
            
            if let data = message.imageData {
                cell.iconImageView?.backgroundColor = nil
                cell.iconImageView?.image = UIImage(data: data)
                cell.iconImageView?.accessibilityLabel = "icon-image-\(message.iterableMessage.messageId)"
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
        
        viewDelegate = delegateClass.init()
    }
    
    private func isNavControllerIterableNavController() -> Bool {
        if let _ = navigationController as? IterableInboxNavigationViewController {
            return true
        }
        return false
    }
    
    private func setModalPresentationStyle(for viewController: UIViewController) {
        guard #available(iOS 13.0, *) else {
            viewController.modalPresentationStyle = .overFullScreen
            return
        }
        
        if let modalPresentationStyle = popupModalPresentationStyle {
            viewController.modalPresentationStyle = modalPresentationStyle
        }
    }
}

@available(iOSApplicationExtension, unavailable)
extension IterableInboxViewController: InboxViewControllerViewModelView {
    func onViewModelChanged(diffs: [RowDiff]) {
        ITBInfo()
        
        guard Thread.isMainThread else {
            ITBError("\(#function) must be called from main thread")
            return
        }
        
        updateTableView(diffs: diffs)
        updateUnreadBadgeCount()
    }
    
    func onImageLoaded(for indexPath: IndexPath) {
        ITBInfo()
        guard Thread.isMainThread else {
            ITBError("\(#function) must be called from main thread")
            return
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    var currentlyVisibleRowIndexPaths: [IndexPath] {
        tableView.indexPathsForVisibleRows?.compactMap(isRowVisible(atIndexPath:)) ?? []
    }
    
    private func updateUnreadBadgeCount() {
        let unreadCount = viewModel.unreadCount
        let badgeValue = unreadCount == 0 ? nil : "\(unreadCount)"
        navigationController?.tabBarItem?.badgeValue = badgeValue
    }
    
    private func updateTableView(diffs: [RowDiff]) {
        tableView.beginUpdates()
        viewModel.beganUpdates()
        
        for diff in diffs {
            switch diff {
            case .delete(let indexPath): tableView.deleteRows(at: [indexPath], with: deletionAnimation)
            case .insert(let indexPath): tableView.insertRows(at: [indexPath], with: insertionAnimation)
            case .update(let indexPath): tableView.reloadRows(at: [indexPath], with: .automatic)
            case .sectionDelete(let indexSet): tableView.deleteSections(indexSet, with: deletionAnimation)
            case .sectionInsert(let indexSet): tableView.insertSections(indexSet, with: insertionAnimation)
            case .sectionUpdate(let indexSet): tableView.reloadSections(indexSet, with: .automatic)
            }
        }

        tableView.endUpdates()
        viewModel.endedUpdates()
    }

    private func isRowVisible(atIndexPath indexPath: IndexPath) -> IndexPath? {
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
        
        return newRect.contains(convertedRect) ? indexPath : nil
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
        guard let customNibNames = viewDelegate.customNibNames, customNibNames.count > 0 else {
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        guard let customNibNameMapper = viewDelegate.customNibNameMapper, let customNibName = customNibNameMapper(message) else {
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: customNibName, for: indexPath) as? IterableInboxCell else {
            ITBError("Please make sure that an the nib: \(customNibName) is present in the main bundle")
            return loadDefaultCell(forTableView: tableView, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    private let defaultCellReuseIdentifier = "inboxCell"
    
    private func registerCustomCells(forTableView tableView: UITableView) {
        guard let viewDelegate = viewDelegate else {
            return
        }
        guard let customNibNames = viewDelegate.customNibNames, customNibNames.count > 0 else {
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
                ITBError("Cannot find nib: \(cellNibName) in main bundle. Using default.")
                tableView.register(IterableInboxCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
            }
        } else {
            tableView.register(IterableInboxCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
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
            fatalError("Could not load default cell")
        }
        
        return cell
    }
}

extension UITableView {
    func setEmptyView(title: String?, message: String?) {
        let emptyView = UIView(frame: self.bounds)
        let titleLabel: UILabel?
        if let title = title {
            titleLabel = UILabel()
            emptyView.addSubview(titleLabel!)
            titleLabel?.translatesAutoresizingMaskIntoConstraints = false
            titleLabel?.textColor = UIColor.black
            titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
            titleLabel?.text = title
            titleLabel?.widthAnchor.constraint(equalTo: emptyView.widthAnchor, multiplier: 1.0, constant: -20).isActive = true
            titleLabel?.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
            titleLabel?.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        } else {
            titleLabel = nil
        }

        if let message = message {
            let messageLabel = UILabel()
            emptyView.addSubview(messageLabel)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.textColor = UIColor.lightGray
            messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 18)
            messageLabel.text = message
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center

            messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
            messageLabel.widthAnchor.constraint(equalTo: emptyView.widthAnchor, multiplier: 1.0, constant: -20).isActive = true
            if let titleLabel = titleLabel {
                messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25).isActive = true
            } else {
                messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
            }
        }

        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
