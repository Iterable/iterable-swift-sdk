//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@IBDesignable
open class IterableInboxViewController: UITableViewController {
    // MARK: Settable properties
    
    /// If you want to use a custom layout for your Inbox TableViewCell
    /// this is where you should override it. Please note that this assumes
    /// that the xib is present in the main bundle.
    @IBInspectable public var cellNibName: String? = nil
    
    /// You can change insertion/deletion animations here.
    public var insertionAnimation = UITableView.RowAnimation.automatic, deletionAnimation = UITableView.RowAnimation.automatic

    // MARK: Initializers
    public override init(style: UITableView.Style) {
        ITBInfo()
        self.viewModel = InboxViewControllerViewModel()
        super.init(style: style)
        viewModel.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        self.viewModel = InboxViewControllerViewModel()
        super.init(coder: aDecoder)
        viewModel.delegate = self
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        self.viewModel = InboxViewControllerViewModel()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        viewModel.delegate = self
    }
    
    override open func viewDidLoad() {
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
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numMessages
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as? IterableInboxCell else {
            fatalError("Please make sure that an the nib: \(cellNibName!) is present in the main bundle")
        }

        configure(cell: cell, forMessage:viewModel.message(atRow: indexPath.row))

        return cell
    }

    // Override to support conditional editing of the table view.
    override open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            viewModel.remove(atRow: indexPath.row)
        }
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let iterableMessage = viewModel.message(atRow: indexPath.row).iterableMessage
        
        if let viewController = IterableAPI.inAppManager.createInboxMessageViewController(for: iterableMessage) {
            IterableAPI.inAppManager.set(read: true, forMessage: iterableMessage)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    var viewModel: InboxViewControllerViewModelProtocol
    
    private let iterableCellNibName = "IterableInboxCell"
    
    deinit {
        ITBInfo()
    }
    
    private func registerTableViewCell() {
        let cellNibName = self.cellNibName ?? self.iterableCellNibName
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

extension IterableInboxViewController : InboxViewControllerViewModelDelegate {
    // Must be called on Main Thread
    func onViewModelChanged(diff: [SectionedDiffStep<Int, InboxMessageViewModel>]) {
        ITBInfo()

        updateTableView(diff: diff)
        updateUnreadBadgeCount()
    }

    // Must be called on Main Thread
    func onImageLoaded(forRow row: Int) {
        ITBInfo()
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
            case let .delete(section, row, _): tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: self.deletionAnimation)
            case let .insert(section, row, _): tableView.insertRows(at: [IndexPath(row: row, section: section)], with: self.insertionAnimation)
            case let .sectionDelete(section, _): tableView.deleteSections(IndexSet(integer: section), with: self.deletionAnimation)
            case let .sectionInsert(section, _): tableView.insertSections(IndexSet(integer: section), with: self.insertionAnimation)
            }
        }
        tableView.endUpdates()
    }
    
}
