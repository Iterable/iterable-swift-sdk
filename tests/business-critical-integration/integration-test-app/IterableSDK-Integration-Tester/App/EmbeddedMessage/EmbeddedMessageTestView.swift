//
//  EmbeddedMessageTestView.swift
//  IterableSDK-Integration-Tester
//

import SwiftUI
import IterableSDK

struct EmbeddedMessageTestView: View {
    @StateObject private var viewModel = EmbeddedMessageTestViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMessagesModal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Section
                statusSection
                
                // User Profile Section
                userProfileSection
                
                // Campaign Triggers
//                campaignTriggersSection
                
                // Embedded Message Display
                embeddedMessagesSection
                
                // Control Buttons
                controlButtonsSection
                
                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .navigationTitle("Embedded Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
                .accessibilityIdentifier("back-to-home-button")
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .alert(item: $viewModel.alertMessage) { alertMessage in
            Alert(
                title: Text(alertMessage.title),
                message: Text(alertMessage.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            
            StatusRow(title: "Embedded Enabled", value: viewModel.isEmbeddedEnabled ? "✓ Enabled" : "✗ Disabled")
                .accessibilityIdentifier("embedded-enabled-value")
            
            StatusRow(title: "Messages Count", value: "\(viewModel.messagesCount)")
                .accessibilityIdentifier("embedded-messages-count")
            
            StatusRow(title: "User Eligibility", value: viewModel.userEligibilityStatus)
                .accessibilityIdentifier("user-eligibility-status")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - User Profile Section
    
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Profile Controls")
                .font(.headline)
            
            HStack {
                Button {
                    viewModel.isPremiumMember = false
                    viewModel.updateUserProfile()
                } label: {
                    Text("Disable Premium Member")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    viewModel.isPremiumMember = true
                    viewModel.updateUserProfile()
                } label: {
                    Text("Enable Premium Member")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .accessibilityIdentifier("premium-member-toggle")
            
            HStack {
                Text("Premium Member: ")
                Text(viewModel.isPremiumMember ? "Yes" : "No")
                    .foregroundColor(viewModel.isPremiumMember ? .green : .gray)
            }
            
            StatusRow(title: "Profile Status", value: viewModel.profileUpdateStatus)
                .accessibilityIdentifier("profile-update-status")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Campaign Triggers Section
    
    private var campaignTriggersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Campaign Triggers")
                .font(.headline)
            
            Button(action: {
                viewModel.sendSilentPushForSync()
            }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("Send Silent Push (Sync)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .accessibilityIdentifier("send-silent-push-sync-button")
            
            StatusRow(title: "Campaign Status", value: viewModel.campaignStatus)
                .accessibilityIdentifier("campaign-status-value")
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Embedded Messages Display Section
    
    private var embeddedMessagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Embedded Messages")
                .font(.headline)
            
            Button(action: {
                viewModel.syncMessages()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Sync Messages")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .accessibilityIdentifier("sync-embedded-messages-button")
            
            if viewModel.embeddedMessages.isEmpty {
                Text("No embedded messages")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .accessibilityIdentifier("no-embedded-messages-label")
            } else {
                Button(action: {
                    showMessagesModal = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.stack.fill")
                        Text("View Messages (\(viewModel.embeddedMessages.count))")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityIdentifier("view-embedded-messages-button")
                .sheet(isPresented: $showMessagesModal) {
                    EmbeddedMessagesModalView(messages: viewModel.embeddedMessages)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Control Buttons Section
    
    private var controlButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.clearMessages()
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Clear All Messages")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .accessibilityIdentifier("clear-embedded-messages-button")
        }
    }
}

// MARK: - Supporting Views

struct EmbeddedMessagesModalView: UIViewControllerRepresentable {
    let messages: [IterableEmbeddedMessage]
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = EmbeddedMessagesViewController(messages: messages)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let vc = uiViewController.viewControllers.first as? EmbeddedMessagesViewController {
            vc.updateMessages(messages)
        }
    }
}

class EmbeddedMessagesViewController: UIViewController {
    private var messages: [IterableEmbeddedMessage]
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    init(messages: [IterableEmbeddedMessage]) {
        self.messages = messages
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayMessages()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.title = "Embedded Messages"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissModal)
        )
        
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // StackView
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func displayMessages() {
        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add message views
        for (index, message) in messages.enumerated() {
            let embeddedView = IterableEmbeddedView(message: message, viewType: .card, config: nil)
            embeddedView.translatesAutoresizingMaskIntoConstraints = false
            embeddedView.accessibilityIdentifier = "embedded-message-\(index)"
            stackView.addArrangedSubview(embeddedView)
            
            NSLayoutConstraint.activate([
                embeddedView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
            ])
        }
    }
    
    func updateMessages(_ messages: [IterableEmbeddedMessage]) {
        self.messages = messages
        if isViewLoaded {
            displayMessages()
        }
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
}


#Preview {
    NavigationView {
        EmbeddedMessageTestView()
    }
}

