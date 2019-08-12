//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@IBDesignable
open class IterableInboxViewController: UITableViewController {
    public enum InboxMode {
        case popup
        case nav
    }
    
    // MARK: Settable properties
    
    /// If you want to use a custom layout for your inbox TableViewCell
    /// this is where you should override it. Please note that this assumes
    /// that the XIB is present in the main bundle.
    @IBInspectable public var cellNibName: String? = nil
    
    /// Set this mode to `popup` to show a popup when an inbox message is selected in the list.
    /// Set this mode to `nav` to push inbox message into navigation stack.
    public var inboxMode = InboxMode.popup
    
    /// You can change insertion/deletion animations here.
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
        
        // Set footer view so that we don't see table view separators
        // for the empty rows.
        tableView.tableFooterView = UIView()
        
        if #available(iOS 10.0, *) {
            let refreshControl = UIRefreshControl()
            refreshControl.attributedTitle = NSAttributedString(string: "Fetching new in-app messages")
            refreshControl.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
        
        registerTableViewCell()
    }
    
    // MARK: - Table view data source
    
    open override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
    
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
    
    // Override to support conditional editing of the table view.
    open override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    open override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            viewModel.remove(atRow: indexPath.row)
        }
    }
    
    open override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        cell.titleLbl?.text = message.title
        cell.subtitleLbl?.text = message.subtitle
        cell.unreadCircleView?.isHidden = message.read
        
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
        
        if let createdAt = message.createdAt {
            cell.createdAtLbl?.isHidden = false
            cell.createdAtLbl?.text = IterableInboxViewController.displayValue(forTime: createdAt)
        } else {
            cell.createdAtLbl?.isHidden = true
        }
    }
    
    private static func displayValue(forTime date: Date) -> String {
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}

extension IterableInboxViewController: InboxViewControllerViewModelDelegate {
    // Must be called on main thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>]) {
        ITBInfo()
        
//        guard Thread.isMainThread else {
//            ITBError("Must be called from main thread")
//            return false
//        }
        
        updateTableView(diff: diff)
        updateUnreadBadgeCount()
    }
    
    // Must be called on main thread
    func onImageLoaded(forRow row: Int) {
        ITBInfo()
        
//        guard Thread.isMainThread else {
//            ITBError("Must be called from main thread")
//            return false
//        }
        
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
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
}
