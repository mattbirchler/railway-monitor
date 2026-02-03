//
//  SetupView.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

struct SetupView: View {
    @Environment(AppState.self) private var appState
    @State private var token = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Railway Monitor")
                .font(.headline)

            Text("Enter your Railway API token to get started.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("API Token", text: $token)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
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
            .disabled(token.isEmpty || isConnecting)

            Link("Create a token at railway.com",
                 destination: URL(string: "https://railway.com/account/tokens")!)
                .font(.caption)
        }
        .padding(20)
        .frame(width: 280)
    }

    private func connect() {
        isConnecting = true
        errorMessage = nil

        Task {
            do {
                try await appState.authenticate(token: token)
            } catch {
                errorMessage = error.localizedDescription
            }
            isConnecting = false
        }
    }
}
