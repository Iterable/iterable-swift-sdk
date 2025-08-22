import UIKit

class NetworkMonitorViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(NetworkRequestCell.self, forCellReuseIdentifier: NetworkRequestCell.identifier)
        return table
    }()
    
    private let clearButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Clear", style: .plain, target: nil, action: nil)
        return button
    }()
    
    private let closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Close", style: .plain, target: nil, action: nil)
        return button
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No network requests yet\nMake some API calls to see them here"
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var requests: [NetworkRequest] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMonitoring()
        loadExistingRequests()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Network Monitor"
        view.backgroundColor = .systemBackground
        
        // Setup navigation
        clearButton.target = self
        clearButton.action = #selector(clearRequests)
        navigationItem.rightBarButtonItem = clearButton
        
        closeButton.target = self
        closeButton.action = #selector(closeModal)
        navigationItem.leftBarButtonItem = closeButton
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        updateEmptyState()
    }
    
    private func setupMonitoring() {
        NetworkMonitor.shared.onRequestAdded = { [weak self] request in
            self?.addRequest(request)
        }
        
        NetworkMonitor.shared.onRequestUpdated = { [weak self] request in
            self?.updateRequest(request)
        }
    }
    
    private func loadExistingRequests() {
        requests = NetworkMonitor.shared.getAllRequests()
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - Actions
    
    @objc private func clearRequests() {
        NetworkMonitor.shared.clearRequests()
        requests.removeAll()
        tableView.reloadData()
        updateEmptyState()
    }
    
    @objc private func closeModal() {
        dismiss(animated: true)
    }
    
    // MARK: - Private Methods
    
    private func addRequest(_ request: NetworkRequest) {
        requests.insert(request, at: 0) // Add to top
        
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .top)
        updateEmptyState()
    }
    
    private func updateRequest(_ request: NetworkRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }
        
        requests[index] = request
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    private func updateEmptyState() {
        emptyLabel.isHidden = !requests.isEmpty
        tableView.isHidden = requests.isEmpty
    }
}

// MARK: - TableView DataSource & Delegate

extension NetworkMonitorViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetworkRequestCell.identifier, for: indexPath) as! NetworkRequestCell
        cell.configure(with: requests[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let request = requests[indexPath.row]
        guard let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty else { return }

        let alert = UIAlertController(title: "Request Parameters", message: nil, preferredStyle: .actionSheet)
        for item in items {
            let value = item.value ?? ""
            alert.addAction(UIAlertAction(title: "\(item.name) = \(value)", style: .default, handler: nil))
        }
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        // For iPad safety
        if let pop = alert.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
        }

        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let request = requests[indexPath.row]
        let detailVC = NetworkRequestDetailViewController(request: request)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - Custom Cell

class NetworkRequestCell: UITableViewCell {
    static let identifier = "NetworkRequestCell"
    
    private let methodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        return label
    }()

    private let paramsButton: UIButton = {
        let button = UIButton(type: .detailDisclosure)
        button.isHidden = true
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemGray
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        [methodLabel, urlLabel, statusLabel, timestampLabel, paramsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            methodLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            methodLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            methodLabel.widthAnchor.constraint(equalToConstant: 50),
            
            urlLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            urlLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 8),
            urlLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            statusLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(equalToConstant: 60),
            
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timestampLabel.widthAnchor.constraint(equalToConstant: 80),

            paramsButton.centerYAnchor.constraint(equalTo: urlLabel.centerYAnchor),
            paramsButton.leadingAnchor.constraint(equalTo: urlLabel.trailingAnchor, constant: 4),
            paramsButton.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -4)
        ])
    }
    
    func configure(with request: NetworkRequest) {
        methodLabel.text = request.method
        // Show only path (hide query)
        if let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false) {
            let path = components.path
            urlLabel.text = path
            // Show params button only if query items exist
            let hasParams = !(components.queryItems ?? []).isEmpty
            paramsButton.isHidden = true // we use tableView accessory instead
            accessoryType = hasParams ? .detailDisclosureButton : .none
        } else {
            urlLabel.text = request.url.path
            paramsButton.isHidden = true
            accessoryType = .none
        }
        
        if let response = request.response {
            statusLabel.text = "\(response.statusCode)"
            statusLabel.textColor = request.statusCodeColor
            
            if let duration = request.duration {
                timestampLabel.text = String(format: "%.2fs", duration)
            } else {
                timestampLabel.text = "..."
            }
        } else {
            statusLabel.text = "..."
            statusLabel.textColor = .systemOrange
            timestampLabel.text = "..."
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        timestampLabel.text = formatter.string(from: request.timestamp)
    }
}
