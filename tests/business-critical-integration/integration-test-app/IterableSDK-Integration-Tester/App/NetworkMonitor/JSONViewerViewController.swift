import UIKit

class JSONViewerViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let copyButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Copy", style: .plain, target: nil, action: nil)
        return button
    }()
    
    // MARK: - Properties
    
    private let data: Data
    private let viewTitle: String
    
    // MARK: - Initialization
    
    init(data: Data, title: String) {
        self.data = data
        self.viewTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = viewTitle
        view.backgroundColor = .systemBackground
        
        // Setup navigation
        copyButton.target = self
        copyButton.action = #selector(copyContent)
        navigationItem.rightBarButtonItem = copyButton
        
        // Setup text view
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureContent() {
        var displayText: String
        
        // Try to parse as JSON first
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            displayText = String(data: prettyData, encoding: .utf8) ?? "Unable to display content"
            
            // Add syntax highlighting for JSON
            textView.attributedText = highlightJSON(displayText)
            
        } catch {
            // If not valid JSON, show as plain text
            displayText = String(data: data, encoding: .utf8) ?? "Unable to display content as text"
            textView.text = displayText
        }
    }
    
    private func highlightJSON(_ jsonString: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: jsonString)
        
        // Base text color
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: jsonString.count))
        
        // Define colors
        let keyColor = UIColor.systemBlue
        let stringColor = UIColor.systemRed
        let numberColor = UIColor.systemPurple
        let boolColor = UIColor.systemOrange
        let nullColor = UIColor.systemGray
        
        // Regular expressions for syntax highlighting
        let patterns: [(NSRegularExpression, UIColor)] = [
            // JSON keys (quoted strings followed by colon)
            (try! NSRegularExpression(pattern: "\"[^\"]*\"\\s*:", options: []), keyColor),
            // String values (quoted strings not followed by colon)
            (try! NSRegularExpression(pattern: "\"[^\"]*\"(?!\\s*:)", options: []), stringColor),
            // Numbers
            (try! NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b", options: []), numberColor),
            // Booleans
            (try! NSRegularExpression(pattern: "\\b(true|false)\\b", options: []), boolColor),
            // Null
            (try! NSRegularExpression(pattern: "\\bnull\\b", options: []), nullColor)
        ]
        
        // Apply highlighting
        for (regex, color) in patterns {
            let matches = regex.matches(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.count))
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
        
        return attributedString
    }
    
    // MARK: - Actions
    
    @objc private func copyContent() {
        UIPasteboard.general.string = textView.text
        
        // Show feedback
        let alert = UIAlertController(title: "Copied", message: "Content copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
