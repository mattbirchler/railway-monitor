//
//  ConnectServiceView.swift
//  Railway Monitor
//

import SwiftUI

/// Token entry form for a single cloud service. Used by first-run setup and by Settings.
struct ConnectServiceView: View {
    @Environment(AppState.self) private var appState
    let service: CloudService
    var onConnected: () -> Void
    var onCancel: (() -> Void)?

    @State private var token = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: service.symbolName)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Connect \(service.displayName)")
                .font(.headline)

            Text(service.setupInstructions)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField(service.credentialLabel, text: $token)
                .textFieldStyle(.roundedBorder)
                .onSubmit(connect)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: connect) {
                if isConnecting {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isConnecting)

            Link("Create a \(service.credentialLabel.lowercased()) at \(service.tokenURL.host() ?? service.displayName)",
                 destination: service.tokenURL)
                .font(.caption)

            if let onCancel {
                Button("Back", action: onCancel)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private func connect() {
        guard !isConnecting else { return }
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                try await appState.connect(service, token: token)
                onConnected()
            } catch {
                errorMessage = error.localizedDescription
            }
            isConnecting = false
        }
    }
}
