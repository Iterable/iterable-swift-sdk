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
                
                // Statistics Section
                statisticsSection
                
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
            
            StatusRow(title: "In-App Enabled", value: viewModel.inAppEnabled ? "✓ Enabled" : "✗ Disabled", valueColor: viewModel.inAppEnabled ? .green : .red)
            StatusRow(title: "Messages Available", value: "\(viewModel.messagesAvailable)", valueColor: viewModel.messagesAvailable > 0 ? .green : .gray)
            StatusRow(title: "Last Sync", value: viewModel.lastSyncTime, valueColor: .primary)
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
                title: "Check for Messages",
                backgroundColor: .blue,
                isLoading: viewModel.isCheckingMessages
            ) {
                viewModel.checkForMessages()
            }
            .accessibilityIdentifier("check-messages-button")
            .disabled(viewModel.isCheckingMessages)
            
            ActionButton(
                title: "Trigger Test In-App (Campaign 14751067)",
                backgroundColor: .green,
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(14751067)
            }
            .accessibilityIdentifier("trigger-in-app-button")
            .disabled(viewModel.isTriggeringCampaign)
            
            ActionButton(
                title: "Trigger Action In-App (Campaign 14751068)",
                backgroundColor: Color(.systemTeal),
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(14751068)
            }
            .accessibilityIdentifier("trigger-action-in-app-button")
            .disabled(viewModel.isTriggeringCampaign)
            
            ActionButton(
                title: "Trigger Deep Link In-App (Campaign 15231325)",
                backgroundColor: .purple,
                isLoading: viewModel.isTriggeringCampaign
            ) {
                viewModel.triggerCampaign(15231325)
            }
            .accessibilityIdentifier("trigger-deeplink-in-app-button")
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
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
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

struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Preview

struct InAppMessageTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InAppMessageTestView()
        }
    }
}

