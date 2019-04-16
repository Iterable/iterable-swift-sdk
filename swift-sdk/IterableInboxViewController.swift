//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

open class IterableInboxViewController: UITableViewController {
    // MARK: Initializers
    public override init(style: UITableView.Style) {
        ITBInfo()
        super.init(style: style)
     
        IterableInboxViewController.setup(instance: self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        ITBInfo()
        super.init(coder: aDecoder)
        
        IterableInboxViewController.setup(instance: self)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        IterableInboxViewController.setup(instance: self)
    }
    
    override open func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
        let nib = UINib(nibName: "IterableInboxCell", bundle: Bundle(for: type(of:self)))
        tableView.register(nib, forCellReuseIdentifier: "inboxCell")
    }

    // MARK: - Table view data source
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "inboxCell", for: indexPath) as! IterableInboxCell

        configure(cell: cell, forViewModel: viewModels[indexPath.row])

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let iterableMessage = viewModels[indexPath.row].iterableMessage
        if let viewController = IterableAPI.inAppManager.createInboxMessageViewController(for: iterableMessage) {
            IterableAPI.inAppManager.set(read: true, forMessage: iterableMessage)
            viewController.navigationItem.title = iterableMessage.inboxMetadata?.title
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    private var viewModels = [InboxMessageViewModel]()

    private static func setup(instance: IterableInboxViewController) {
        NotificationCenter.default.addObserver(instance, selector: #selector(onInboxChanged(notification:)), name: .iterableInboxChanged, object: nil)
    }
    
    deinit {
        ITBInfo()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func onInboxChanged(notification: NSNotification) {
        ITBInfo()
        refreshMessages()
    }
    
    private func refreshMessages() {
        viewModels.removeAll()
        IterableAPI.inAppManager.getInboxMessages().forEach {
            viewModels.append(InboxMessageViewModel.from(message: $0))
        }

        let unreadCount = IterableAPI.inAppManager.getUnreadInboxMessagesCount()
        let badgeValue = unreadCount == 0 ? nil : "\(unreadCount)"

        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.tabBarItem?.badgeValue = badgeValue
            self?.tableView.reloadData()
        }
    }

    private func configure(cell: IterableInboxCell, forViewModel viewModel: InboxMessageViewModel) {
        cell.titleLbl.text = viewModel.title
        cell.subTitleLbl.text = viewModel.subTitle
        cell.readCircleView.isHidden = viewModel.read
        
        cell.iconImageView.layer.cornerRadius = 5
        cell.iconImageView.clipsToBounds = true

        if let imageUrlString = viewModel.imageUrl, let url = URL(string: imageUrlString) {
            if let data = viewModel.imageData {
                cell.iconImageView.image = UIImage(data: data)
            } else {
                cell.iconImageView.backgroundColor = UIColor(hex: "EEEEEE") // loading image
                loadImage(forMessageId: viewModel.iterableMessage.messageId, fromUrl: url)
            }
        } else {
            cell.rightView.isHidden = true
        }
        
        cell.timeLbl.isHidden = true
    }

    private func loadImage(forMessageId messageId: String, fromUrl url: URL) {
        if let networkSession = IterableAPIInternal._sharedInstance?.networkSession {
            NetworkHelper.getData(fromUrl: url, usingSession: networkSession).onSuccess {[weak self] in
                self?.updateCell(forMessageId: messageId, withData: $0)
            }.onError {
                ITBError($0.localizedDescription)
            }
        }
    }
    
    private func updateCell(forMessageId messageId: String, withData data: Data) {
        guard let row = viewModels.firstIndex (where: { $0.iterableMessage.messageId == messageId }) else {
            return
        }
        var viewModel = viewModels[row]
        viewModel.imageData = data
        viewModels[row] = viewModel
        
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
}
