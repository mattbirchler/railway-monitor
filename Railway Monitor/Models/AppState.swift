//
//  AppState.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import SwiftUI

@Observable
final class AppState {
    // Auth
    var isAuthenticated = false

    // Workspace
    var workspaces: [Workspace] = []
    var selectedWorkspaceId: String? {
        didSet {
            if let id = selectedWorkspaceId {
                UserDefaults.standard.set(id, forKey: "selectedWorkspaceId")
            }
        }
    }
    var workspaceName: String = ""
    var workspacePlan: String = ""

    // Billing
    var currentUsage: Double = 0
    var creditBalance: Double = 0
    var billingPeriodStart: Date?
    var billingPeriodEnd: Date?

    // Projects
    var projects: [Project] = []

    // Deployments
    var recentDeployments: [Deployment] = []

    // UI State
    var lastRefreshed: Date?
    var isLoading = false
    var error: String?

    // Settings
    var showCostInMenuBar: Bool {
        get { UserDefaults.standard.bool(forKey: "showCostInMenuBar") }
        set { UserDefaults.standard.set(newValue, forKey: "showCostInMenuBar") }
    }

    var refreshIntervalMinutes: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "refreshIntervalMinutes")
            return val > 0 ? val : 5
        }
        set { UserDefaults.standard.set(newValue, forKey: "refreshIntervalMinutes") }
    }

    // API
    let api = RailwayAPI()
    private var refreshTask: Task<Void, Never>?

    // MARK: - Menu Bar Label

    var menuBarTitle: String {
        if showCostInMenuBar && isAuthenticated {
            return String(format: "$%.2f", currentUsage)
        }
        return ""
    }

    // MARK: - Initialization

    private var hasInitialized = false

    func initialize() async {
        guard !hasInitialized else { return }
        hasInitialized = true

        await api.loadTokenFromKeychain()
        let hasToken = await api.hasToken
        if hasToken {
            isAuthenticated = true
            selectedWorkspaceId = UserDefaults.standard.string(forKey: "selectedWorkspaceId")
            await refreshAll()
        }
        startAutoRefresh()
    }

    // MARK: - Authentication

    func authenticate(token: String) async throws {
        await api.setToken(token)
        let workspaces = try await api.validateTokenAndGetWorkspaces()

        if workspaces.isEmpty {
            throw RailwayAPIError.invalidToken
        }

        _ = KeychainService.save(token: token)
        self.workspaces = workspaces
        self.selectedWorkspaceId = workspaces.first?.id
        self.isAuthenticated = true
        await refreshAll()
    }

    func signOut() {
        KeychainService.delete()
        isAuthenticated = false
        workspaces = []
        selectedWorkspaceId = nil
        workspaceName = ""
        workspacePlan = ""
        currentUsage = 0
        creditBalance = 0
        billingPeriodStart = nil
        billingPeriodEnd = nil
        projects = []
        recentDeployments = []
        lastRefreshed = nil
        error = nil
    }

    // MARK: - Data Refresh

    func refreshAll() async {
        guard let workspaceId = selectedWorkspaceId else {
            // Try to discover workspaces first
            do {
                let workspaces = try await api.validateTokenAndGetWorkspaces()
                self.workspaces = workspaces
                if let first = workspaces.first {
                    self.selectedWorkspaceId = first.id
                    await refreshAll()
                }
            } catch {
                self.error = error.localizedDescription
            }
            return
        }

        isLoading = true
        error = nil

        // Fetch workspace detail
        do {
            let detail = try await api.fetchWorkspaceDetail(workspaceId: workspaceId)
            workspaceName = detail.name
            workspacePlan = detail.plan
            currentUsage = detail.customer.currentUsage
            creditBalance = detail.customer.creditBalance

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            billingPeriodStart = isoFormatter.date(from: detail.customer.billingPeriod.start)
            billingPeriodEnd = isoFormatter.date(from: detail.customer.billingPeriod.end)

            if billingPeriodStart == nil {
                isoFormatter.formatOptions = [.withInternetDateTime]
                billingPeriodStart = isoFormatter.date(from: detail.customer.billingPeriod.start)
                billingPeriodEnd = isoFormatter.date(from: detail.customer.billingPeriod.end)
            }
        } catch {
            self.error = error.localizedDescription
        }

        // Fetch projects
        do {
            let fetchedProjects = try await api.fetchProjects(workspaceId: workspaceId)
            projects = fetchedProjects

            // Fetch recent deployments from all projects
            var allDeployments: [Deployment] = []
            for project in fetchedProjects {
                do {
                    let deployments = try await api.fetchDeployments(projectId: project.id, limit: 5)
                    allDeployments.append(contentsOf: deployments)
                } catch {
                    // Skip projects where deployment fetch fails
                }
            }

            recentDeployments = allDeployments
                .sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
                .prefix(10)
                .map { $0 }
        } catch {
            if self.error == nil {
                self.error = error.localizedDescription
            }
        }

        lastRefreshed = Date()
        isLoading = false
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        let interval = UInt64(refreshIntervalMinutes) * 60 * 1_000_000_000
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                guard !Task.isCancelled else { break }
                await refreshAll()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func restartAutoRefresh() {
        startAutoRefresh()
    }
}
