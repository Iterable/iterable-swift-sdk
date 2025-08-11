import UIKit

class NetworkRequestDetailViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let requestSection = DetailSectionView(title: "REQUEST")
    private let responseSection = DetailSectionView(title: "RESPONSE")
    private let viewResponseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Response JSON", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private let request: NetworkRequest
    
    // MARK: - Initialization
    
    init(request: NetworkRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Request Details"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        let stackView = UIStackView(arrangedSubviews: [
            requestSection,
            responseSection,
            viewResponseButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        viewResponseButton.addTarget(self, action: #selector(viewResponseTapped), for: .touchUpInside)
    }
    
    private func configureData() {
        // Configure request section
        var requestData: [String: String] = [:]
        requestData["URL"] = request.url.absoluteString
        requestData["Method"] = request.method
        requestData["Timestamp"] = DateFormatter.fullFormatter.string(from: request.timestamp)
        
        // Add headers
        for (key, value) in request.headers {
            requestData["Header: \(key)"] = value
        }
        
        // Add body if present
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            requestData["Body"] = bodyString
        }
        
        requestSection.configure(with: requestData)
        
        // Configure response section
        if let response = request.response {
            var responseData: [String: String] = [:]
            responseData["Status Code"] = "\(response.statusCode)"
            responseData["Timestamp"] = DateFormatter.fullFormatter.string(from: response.timestamp)
            
            if let duration = request.duration {
                responseData["Duration"] = String(format: "%.3f seconds", duration)
            }
            
            // Add response headers
            for (key, value) in response.headers {
                responseData["Header: \(key)"] = value
            }
            
            // Add error if present
            if let error = response.error {
                responseData["Error"] = error.localizedDescription
            }
            
            responseSection.configure(with: responseData)
            
            // Enable/disable response button based on data availability
            viewResponseButton.isEnabled = response.data != nil
            viewResponseButton.alpha = response.data != nil ? 1.0 : 0.5
        } else {
            responseSection.configure(with: ["Status": "No response yet"])
            viewResponseButton.isEnabled = false
            viewResponseButton.alpha = 0.5
        }
    }
    
    // MARK: - Actions
    
    @objc private func viewResponseTapped() {
        guard let response = request.response, let data = response.data else { return }
        
        let jsonVC = JSONViewerViewController(data: data, title: "Response")
        navigationController?.pushViewController(jsonVC, animated: true)
    }
}

// MARK: - Detail Section View

class DetailSectionView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        return view
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        [titleLabel, containerView, contentStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addSubview(titleLabel)
        addSubview(containerView)
        containerView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with data: [String: String]) {
        // Clear existing content
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new content
        for (key, value) in data.sorted(by: { $0.key < $1.key }) {
            let rowView = createRowView(key: key, value: value)
            contentStackView.addArrangedSubview(rowView)
        }
    }
    
    private func createRowView(key: String, value: String) -> UIView {
        let containerView = UIView()
        
        let keyLabel = UILabel()
        keyLabel.text = key
        keyLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        keyLabel.textColor = .secondaryLabel
        keyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 13)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
