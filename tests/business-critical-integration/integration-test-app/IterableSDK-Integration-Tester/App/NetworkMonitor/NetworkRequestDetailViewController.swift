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
    
    private let viewRequestBodyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Request Body JSON", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let copyDetailsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy Request Details", for: .normal)
        button.backgroundColor = .systemOrange
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
            viewRequestBodyButton,
            responseSection,
            viewResponseButton,
            copyDetailsButton
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
        viewRequestBodyButton.addTarget(self, action: #selector(viewRequestBodyTapped), for: .touchUpInside)
        copyDetailsButton.addTarget(self, action: #selector(copyDetailsTapped), for: .touchUpInside)
    }
    
    private func configureData() {
        // Configure request section
        var requestData: [String: String] = [:]
        if let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false) {
            requestData["Path"] = components.path
            // Add query params as separate rows
            if let items = components.queryItems, !items.isEmpty {
                for item in items.sorted(by: { $0.name < $1.name }) {
                    requestData["Param: \(item.name)"] = item.value ?? ""
                }
            }
        } else {
            requestData["Path"] = request.url.path
        }
        requestData["Method"] = request.method
        requestData["Timestamp"] = DateFormatter.fullFormatter.string(from: request.timestamp)
        
        // Add headers
        for (key, value) in request.headers {
            requestData["Header: \(key)"] = value
        }
        
        // Add body preview if present (truncated for overview)
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            let preview = bodyString.count > 200 ? String(bodyString.prefix(200)) + "..." : bodyString
            requestData["Body Preview"] = preview
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
        
        // Show request body button only for non-GET methods and when body exists
        let isGetMethod = request.method.uppercased() == "GET"
        let hasBody = request.body != nil
        let shouldShow = !isGetMethod && hasBody
        
        print("🔍 Request body button logic: method=\(request.method), hasBody=\(hasBody), shouldShow=\(shouldShow)")
        if let body = request.body {
            print("🔍 Body size: \(body.count) bytes")
        }
        
        viewRequestBodyButton.isHidden = !shouldShow
        viewRequestBodyButton.isEnabled = shouldShow
        viewRequestBodyButton.alpha = shouldShow ? 1.0 : 0.5
    }
    
    // MARK: - Actions
    
    @objc private func viewResponseTapped() {
        guard let response = request.response, let data = response.data else { return }
        
        let jsonVC = JSONViewerViewController(data: data, title: "Response")
        navigationController?.pushViewController(jsonVC, animated: true)
    }
    
    @objc private func viewRequestBodyTapped() {
        guard let body = request.body else { return }
        
        let jsonVC = JSONViewerViewController(data: body, title: "Request Body")
        navigationController?.pushViewController(jsonVC, animated: true)
    }
    
    @objc private func copyDetailsTapped() {
        let details = generateRequestDetailsString()
        UIPasteboard.general.string = details
        
        // Show feedback
        let alert = UIAlertController(title: "Copied!", message: "Request details copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func generateRequestDetailsString() -> String {
        var details = ""
        
        // Request section
        details += "🔵 REQUEST DETAILS\n"
        details += "==================\n"
        details += "URL: \(request.url.absoluteString)\n"
        details += "Method: \(request.method)\n"
        details += "Timestamp: \(DateFormatter.fullFormatter.string(from: request.timestamp))\n\n"
        
        // Request headers
        if !request.headers.isEmpty {
            details += "📋 REQUEST HEADERS:\n"
            for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
                details += "\(key): \(value)\n"
            }
            details += "\n"
        }
        
        // Request body
        if let body = request.body {
            details += "📝 REQUEST BODY:\n"
            if let bodyString = String(data: body, encoding: .utf8) {
                // Try to format as JSON if possible
                if let jsonData = try? JSONSerialization.jsonObject(with: body),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    details += prettyString
                } else {
                    details += bodyString
                }
            } else {
                details += "[Binary data - \(body.count) bytes]"
            }
            details += "\n\n"
        }
        
        // Response section
        if let response = request.response {
            details += "🟢 RESPONSE DETAILS\n"
            details += "===================\n"
            details += "Status Code: \(response.statusCode)\n"
            details += "Timestamp: \(DateFormatter.fullFormatter.string(from: response.timestamp))\n"
            
            if let duration = request.duration {
                details += "Duration: \(String(format: "%.3f", duration)) seconds\n"
            }
            details += "\n"
            
            // Response headers
            if !response.headers.isEmpty {
                details += "📋 RESPONSE HEADERS:\n"
                for (key, value) in response.headers.sorted(by: { $0.key < $1.key }) {
                    details += "\(key): \(value)\n"
                }
                details += "\n"
            }
            
            // Response body
            if let data = response.data {
                details += "📄 RESPONSE BODY:\n"
                if let jsonString = response.jsonString {
                    details += jsonString
                } else if let bodyString = String(data: data, encoding: .utf8) {
                    details += bodyString
                } else {
                    details += "[Binary data - \(data.count) bytes]"
                }
                details += "\n\n"
            }
            
            // Error if present
            if let error = response.error {
                details += "❌ ERROR:\n"
                details += error.localizedDescription
                details += "\n\n"
            }
        } else {
            details += "⏳ RESPONSE: No response yet\n\n"
        }
        
        details += "Generated by Iterable Integration Test App"
        return details
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
