//
//  SettingsView.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI
import ServiceManagement

/// Preferences panel for managing connected services, the menu bar display,
/// refresh interval, launch-at-login, and Railway workspace selection.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    var onDismiss: () -> Void
    @State private var launchAtLogin = false
    @State private var connectingService: CloudService?

    private let refreshOptions = [1, 2, 5, 10, 15, 30]

    var body: some View {
        if let service = connectingService {
            ConnectServiceView(
                service: service,
                onConnected: { connectingService = nil },
                onCancel: { connectingService = nil }
            )
        } else {
            settings
        }
    }

    private var settings: some View {
        @Bindable var state = appState

        return VStack(alignment: .leading, spacing: 16) {
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

            // Services
            VStack(alignment: .leading, spacing: 8) {
                Text("Services")
                    .font(.subheadline.weight(.medium))

                ForEach(CloudService.allCases) { service in
                    serviceRow(service)
                    if service == .openRouter {
                        ForEach(appState.openRouterWorkspaces) { workspace in
                            openRouterWorkspaceRow(workspace)
                        }
                    }
                }
            }

            // Railway workspace selector (if multiple)
            if appState.isRailwayConnected && appState.workspaces.count > 1 {
                HStack {
                    Text("Railway workspace")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $state.selectedWorkspaceId) {
                        ForEach(appState.workspaces) { workspace in
                            Text(workspace.name).tag(Optional(workspace.id))
                        }
                    }
                    .frame(width: 140)
                    .onChange(of: appState.selectedWorkspaceId) {
                        Task {
                            await appState.refreshRailway()
                        }
                    }
                }
            }

            Divider()

            // Show cost in menu bar
            Toggle("Show total cost in menu bar", isOn: $state.showCostInMenuBar)
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

            Button("Quit Railway Monitor") {
                NSApplication.shared.terminate(nil)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func serviceRow(_ service: CloudService) -> some View {
        HStack {
            Image(systemName: service.symbolName)
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(service.displayName)
                .font(.subheadline)
            Spacer()
            if service == .openRouter && appState.isOpenRouterConnected {
                Button("Add Workspace") {
                    connectingService = service
                }
                .font(.caption)
            } else if appState.isConnected(service) {
                Text("Connected")
                    .font(.caption)
                    .foregroundStyle(.green)
                Button("Sign Out") {
                    appState.disconnect(service)
                }
                .font(.caption)
                .foregroundStyle(.red)
            } else {
                Button("Connect") {
                    connectingService = service
                }
                .font(.caption)
            }
        }
    }

    private func openRouterWorkspaceRow(_ workspace: AppState.OpenRouterWorkspace) -> some View {
        HStack {
            Image(systemName: "key")
                .font(.caption)
                .frame(width: 18)
                .foregroundStyle(.tertiary)
            Text(workspace.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Button("Remove") {
                appState.removeOpenRouterWorkspace(id: workspace.id)
            }
            .font(.caption)
            .foregroundStyle(.red)
        }
        .padding(.leading, 18)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail. The user can retry.
        }
    }
}
