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
        if !appState.isAuthenticated {
            SetupView()
        } else if showSettings {
            SettingsView(onDismiss: { showSettings = false })
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            header
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Cost card
                    CostCard(
                        currentUsage: appState.currentUsage,
                        creditBalance: appState.creditBalance,
                        billingPeriodStart: appState.billingPeriodStart,
                        billingPeriodEnd: appState.billingPeriodEnd
                    )

                    // Projects
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

                    // Recent deployments
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

                    // Error
                    if let error = appState.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 400)

            Divider()

            // Footer
            footer
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.workspaceName)
                    .font(.headline)
                Text(appState.workspacePlan.uppercased())
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            Spacer()

            if appState.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

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

                Link(destination: URL(string: "https://railway.com/dashboard")!) {
                    Image(systemName: "arrow.up.right.square")
                }

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
