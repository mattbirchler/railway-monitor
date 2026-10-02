//
//  MenuBarView.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

/// Root view displayed inside the menu bar popover.
/// Routes between the setup flow, settings panel, and the main dashboard.
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        if !appState.hasAnyService {
            SetupView()
        } else if showSettings {
            SettingsView(onDismiss: { showSettings = false })
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if appState.isRailwayConnected {
                        railwaySection
                    }
                    if appState.isDigitalOceanConnected {
                        digitalOceanSection
                    }
                    if appState.isOpenRouterConnected {
                        openRouterSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 460)

            Divider()

            footer
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Spend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "$%.2f", appState.totalCurrentSpend))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            }

            Spacer()

            if appState.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(serviceCountLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var serviceCountLabel: String {
        let count = appState.connectedServices.count
        return count == 1 ? "1 service" : "\(count) services"
    }

    // MARK: - Railway

    private var railwaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ServiceSectionHeader(service: .railway, subtitle: railwaySubtitle)

            CostCard(
                currentUsage: appState.currentUsage,
                creditBalance: appState.creditBalance,
                billingPeriodStart: appState.billingPeriodStart,
                billingPeriodEnd: appState.billingPeriodEnd
            )

            if !appState.projects.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projects")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(appState.projects) { project in
                        ProjectRow(
                            project: project,
                            deployments: appState.recentDeployments.filter { deployment in
                                project.services.edges.contains { edge in
                                    edge.node.name == deployment.service?.name
                                }
                            }
                        )
                    }
                }
            }

            if !appState.recentDeployments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Deployments")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(appState.recentDeployments.prefix(5)) { deployment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(deployment.service?.name ?? "Unknown")
                                    .font(.callout)
                                Text(deployment.timeAgo)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            DeploymentStatusBadge(status: deployment.status)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if let error = appState.railwayError {
                ServiceErrorBanner(message: error)
            }
        }
    }

    private var railwaySubtitle: String {
        var parts: [String] = []
        if !appState.workspaceName.isEmpty { parts.append(appState.workspaceName) }
        if !appState.workspacePlan.isEmpty { parts.append(appState.workspacePlan.capitalized) }
        return parts.joined(separator: " · ")
    }

    // MARK: - DigitalOcean

    private var digitalOceanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ServiceSectionHeader(service: .digitalOcean)

            if let balance = appState.digitalOceanBalance {
                DigitalOceanCard(balance: balance, invoices: appState.digitalOceanInvoices)
            } else if appState.digitalOceanError == nil {
                loadingPlaceholder
            }

            if let error = appState.digitalOceanError {
                ServiceErrorBanner(message: error)
            }
        }
    }

    // MARK: - OpenRouter

    private var openRouterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ServiceSectionHeader(service: .openRouter, subtitle: openRouterSubtitle)

            ForEach(appState.openRouterWorkspaces) { workspace in
                if let account = workspace.account {
                    OpenRouterCard(name: workspace.name, account: account)
                } else if workspace.error == nil {
                    loadingPlaceholder
                }

                if let error = workspace.error {
                    ServiceErrorBanner(message: "\(workspace.name): \(error)")
                }
            }
        }
    }

    private var openRouterSubtitle: String? {
        guard appState.openRouterWorkspaces.count > 1, let total = appState.openRouterMonthlySpend else {
            return nil
        }
        return String(format: "$%.2f this month", total)
    }

    private var loadingPlaceholder: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            if let lastRefreshed = appState.lastRefreshed {
                Text("Updated \(lastRefreshed, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await appState.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(appState.isLoading)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }
}
