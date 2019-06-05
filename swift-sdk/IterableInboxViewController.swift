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
    
    // MARK: Initializers
    public override init(style: UITableView.Style) {
        ITBInfo()
        super.init(style: style)
     
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        super.init(coder: aDecoder)
        
        setup()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        setup()
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
        return diffCalculator?.rows.count ?? 0
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as? IterableInboxCell else {
            fatalError("Please make sure that an the nib: \(cellNibName!) is present in the main bundle")
        }

        if let viewModel = diffCalculator?.rows[indexPath.row] {
            configure(cell: cell, forViewModel: viewModel)
        }

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
            guard let iterableMessage = diffCalculator?.rows[indexPath.row].iterableMessage else {
                return
            }
            IterableAPI.inAppManager.remove(message: iterableMessage)
        }
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let iterableMessage = diffCalculator?.rows[indexPath.row].iterableMessage else {
            return
        }
        if let viewController = IterableAPI.inAppManager.createInboxMessageViewController(for: iterableMessage) {
            IterableAPI.inAppManager.set(read: true, forMessage: iterableMessage)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private let iterableCellNibName = "IterableInboxCell"
    
    private lazy var diffCalculator: SingleSectionTableViewDiffCalculator<InboxMessageViewModel>? = {
        SingleSectionTableViewDiffCalculator(tableView: self.tableView)
    }()
    
    private func setup() {
        refreshMessages()
        NotificationCenter.default.addObserver(self, selector: #selector(onInboxChanged(notification:)), name: .iterableInboxChanged, object: nil)
    }

    deinit {
        ITBInfo()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func registerTableViewCell() {
        let cellNibName = self.cellNibName ?? self.iterableCellNibName
        let bundle = self.cellNibName == nil ? Bundle(for: IterableInboxViewController.self) : Bundle.main
        
        let nib = UINib(nibName: cellNibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: "inboxCell")
    }
    
    @objc private func onInboxChanged(notification: NSNotification) {
        ITBInfo()
        refreshMessages()
    }
    
    private func refreshMessages() {
        ITBInfo()
        DispatchQueue.main.async { [weak self] in
            self?.updateUnreadBadgeCount()
            self?.diffCalculator?.rows = IterableAPI.inAppManager.getInboxMessages().map { InboxMessageViewModel(message: $0) }
        }
    }
    
    private func updateUnreadBadgeCount() {
        let unreadCount = IterableAPI.inAppManager.getUnreadInboxMessagesCount()
        let badgeValue = unreadCount == 0 ? nil : "\(unreadCount)"
        navigationController?.tabBarItem?.badgeValue = badgeValue
    }
    
    @available(iOS 10.0, *)
    @objc private func handleRefreshControl() {
        ITBInfo()
        
        if let inAppManager = IterableAPI.inAppManager as? InAppManager {
            inAppManager.onInAppSyncNeeded()
        }
        
        tableView.refreshControl?.endRefreshing()
    }
    
    private func configure(cell: IterableInboxCell, forViewModel viewModel: InboxMessageViewModel) {
        cell.titleLbl?.text = viewModel.title
        cell.subtitleLbl?.text = viewModel.subtitle
        cell.unreadCircleView?.isHidden = viewModel.read
        
        cell.iconImageView?.clipsToBounds = true

        if let imageUrlString = viewModel.imageUrl, let url = URL(string: imageUrlString) {
            cell.iconContainerView?.isHidden = false
            cell.iconImageView?.isHidden = false

            if let data = viewModel.imageData {
                cell.iconImageView?.backgroundColor = nil
                cell.iconImageView?.image = UIImage(data: data)
            } else {
                cell.iconImageView?.backgroundColor = UIColor(hex: "EEEEEE") // loading image
                cell.iconImageView?.image = nil
                loadImage(forMessageId: viewModel.iterableMessage.messageId, fromUrl: url)
            }
        } else {
            cell.iconContainerView?.isHidden = true
            cell.iconImageView?.isHidden = true
        }
        
        if let createdAt = viewModel.createdAt {
            cell.createdAtLbl?.isHidden = false
            cell.createdAtLbl?.text = IterableInboxViewController.displayValue(forTime: createdAt)
        } else {
            cell.createdAtLbl?.isHidden = true
        }
    }

    private func loadImage(forMessageId messageId: String, fromUrl url: URL) {
        if let networkSession = IterableAPI.internalImplementation?.networkSession {
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess {[weak self] in
                self?.updateCell(forMessageId: messageId, withImageData: $0)
            }.onError {
                ITBError($0.localizedDescription)
            }
        }
    }
    
    private func updateCell(forMessageId messageId: String, withImageData data: Data) {
        guard var viewModels = diffCalculator?.rows else {
            return
        }
        guard let row = viewModels.firstIndex (where: { $0.iterableMessage.messageId == messageId }) else {
            return
        }
        let viewModel = viewModels[row]
        viewModel.imageData = data

        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    private static func displayValue(forTime date: Date) -> String {
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
}
