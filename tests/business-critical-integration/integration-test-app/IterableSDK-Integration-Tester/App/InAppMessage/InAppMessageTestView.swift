//
//  InAppMessageTestView.swift
//  IterableSDK-Integration-Tester
//

import SwiftUI
import IterableSDK

struct InAppMessageTestView: View {
    @StateObject private var viewModel = InAppMessageTestViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Section
                statusSection
                
                // Control Buttons
                controlButtonsSection
                
                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .navigationTitle("In-App Messages")
        .navigationBarTitleDisplayMode(.inline)
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
            Text("In-App Message Status")
                .font(.system(size: 18, weight: .semibold))
            
            StatusRow(
                title: "In-App Enabled",
                value: viewModel.inAppEnabled ? "✓ Enabled" : "✗ Disabled",
                valueColor: viewModel.inAppEnabled ? .green : .red
            )
            
            StatusRow(
                title: "Messages Available",
                value: "\(viewModel.messagesAvailable)",
                valueColor: viewModel.messagesAvailable > 0 ? .green : .gray
            )
            StatusRow(
                title: "Last Sync",
                value: viewModel.lastSyncTime,
                valueColor: .primary
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtonsSection: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: viewModel.inAppEnabled ? "Disable In-App Messages" : "Enable In-App Messages",
                backgroundColor: viewModel.inAppEnabled ? .orange : .green,
                isLoading: false
            ) {
                viewModel.toggleInApp()
            }
            .accessibilityIdentifier("toggle-in-app-button")
            
            ActionButton(
                title: "Get Messages",
                backgroundColor: .blue,
                isLoading: viewModel.isCheckingMessages
            ) {
                viewModel.checkForMessages()
            }
            .accessibilityIdentifier("check-messages-button")
            .disabled(viewModel.isCheckingMessages)
            
            ActionButton(
                title: "Send In-App Message (Campaign 14751067)",
                backgroundColor: .green,
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(14751067)
            }
            .accessibilityIdentifier("trigger-in-app-button")
            .disabled(viewModel.isTriggeringCampaign)
            
            ActionButton(
                title: "Send DeepLink In-App Message (Campaign 15231325)",
                backgroundColor: Color(.systemIndigo),
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(15231325)
            }
            .accessibilityIdentifier("trigger-testview-in-app-button")
            .disabled(viewModel.isTriggeringCampaign)

            ActionButton(
                title: "Send Full Screen In-App (SDK-31 Test)",
                backgroundColor: Color(.systemPurple),
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(16505358)
            }
            .accessibilityIdentifier("trigger-fullscreen-in-app-button")
            .disabled(viewModel.isTriggeringCampaign)

            ActionButton(
                title: "Test Local Full-Screen IAM (POC)",
                backgroundColor: Color(.systemTeal),
                isLoading: false
            ) {
                viewModel.showLocalFullScreenIAM()
            }
            .accessibilityIdentifier("test-local-fullscreen-button")

            ActionButton(
                title: "Send Silent Push (Campaign 14750476)",
                backgroundColor: Color(.brown),
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.sendSilentPush(14750476)
            }
            .accessibilityIdentifier("trigger-test-silent-push-button")
            .disabled(viewModel.isTriggeringCampaign)
            
            
            ActionButton(
                title: "Clear Message Queue",
                backgroundColor: .red,
                isLoading: viewModel.isClearingMessages
            ) {
                viewModel.clearMessageQueue()
            }
            .accessibilityIdentifier("clear-messages-button")
            .disabled(viewModel.isClearingMessages)
            
            ActionButton(
                title: "Back to Home Screen",
                backgroundColor: .gray,
                isLoading: false
                , action: {
                    dismiss()
                })
            .accessibilityIdentifier("back-to-home-button")
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In-App Message Statistics")
                .font(.system(size: 18, weight: .semibold))
            
            StatusRow(title: "Messages Shown", value: "\(viewModel.messagesShown)", valueColor: .primary)
            StatusRow(title: "Messages Clicked", value: "\(viewModel.messagesClicked)", valueColor: .primary)
            StatusRow(title: "Messages Dismissed", value: "\(viewModel.messagesDismissed)", valueColor: .primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let title: String
    let value: String
    var valueColor: Color = .accentColor
    
    init(title: String, value: String, valueColor: Color? = nil) {
        self.title = title
        if let valueColor = valueColor {
            self.valueColor = valueColor
        }
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .accessibilityIdentifier(title)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
                .accessibilityIdentifier(value)
        }
    }
}

struct ActionButton: View {
    let title: String
    let backgroundColor: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Spacer().frame(width: 8)
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 44)
            .background(backgroundColor)
            .cornerRadius(8)
        }
    }
}

// MARK: - Alert Message

public struct AlertMessage: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
}

// MARK: - Preview

struct InAppMessageTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InAppMessageTestView()
        }
    }
}

