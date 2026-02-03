//
//  SettingsView.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    var onDismiss: () -> Void
    @State private var launchAtLogin = false

    private let refreshOptions = [1, 2, 5, 10, 15, 30]

    var body: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // API Token
            VStack(alignment: .leading, spacing: 4) {
                Text("API Token")
                    .font(.subheadline.weight(.medium))
                HStack {
                    Text("••••••••••••••••")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Sign Out") {
                        appState.signOut()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }

            Divider()

            // Show cost in menu bar
            Toggle("Show cost in menu bar", isOn: $state.showCostInMenuBar)
                .font(.subheadline)

            // Refresh interval
            HStack {
                Text("Refresh interval")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $state.refreshIntervalMinutes) {
                    ForEach(refreshOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .frame(width: 100)
                .onChange(of: appState.refreshIntervalMinutes) {
                    appState.restartAutoRefresh()
                }
            }

            // Launch at login
            Toggle("Launch at login", isOn: $launchAtLogin)
                .font(.subheadline)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

            Divider()

            // Workspace selector (if multiple)
            if appState.workspaces.count > 1 {
                HStack {
                    Text("Workspace")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $state.selectedWorkspaceId) {
                        ForEach(appState.workspaces) { workspace in
                            Text(workspace.name).tag(Optional(workspace.id))
                        }
                    }
                    .frame(width: 150)
                    .onChange(of: appState.selectedWorkspaceId) {
                        Task {
                            await appState.refreshAll()
                        }
                    }
                }

                Divider()
            }

            Button("Quit Railway Monitor") {
                NSApplication.shared.terminate(nil)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail — user can retry
        }
    }
}
