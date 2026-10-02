//
//  AppState.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import SwiftUI

/// Central app state shared across all views via the SwiftUI environment.
/// Tracks which cloud services are connected, holds the latest data for each,
/// and runs a configurable auto-refresh timer.
@Observable
final class AppState {
    // MARK: - Railway

    var isRailwayConnected = false
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
    var currentUsage: Double = 0
    var creditBalance: Double = 0
    var billingPeriodStart: Date?
    var billingPeriodEnd: Date?
    var projects: [Project] = []
    var recentDeployments: [Deployment] = []
    var railwayError: String?

    // MARK: - DigitalOcean

    var isDigitalOceanConnected = false
    var digitalOceanBalance: DigitalOceanBalance?
    var digitalOceanInvoices: [DigitalOceanInvoice] = []
    var digitalOceanError: String?

    // MARK: - OpenRouter

    var isOpenRouterConnected = false
    var openRouterAccount: OpenRouterAccount?
    var openRouterError: String?

    // MARK: - UI State

    var lastRefreshed: Date?
    var isLoading = false

    // MARK: - Settings (persisted in UserDefaults)

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

    // MARK: - API clients

    let railwayAPI = RailwayAPI()
    let digitalOceanAPI = DigitalOceanAPI()
    let openRouterAPI = OpenRouterAPI()
    private var refreshTask: Task<Void, Never>?

    // MARK: - Derived state

    /// Services the user has connected, in display order.
    var connectedServices: [CloudService] {
        CloudService.allCases.filter { isConnected($0) }
    }

    var hasAnyService: Bool {
        !connectedServices.isEmpty
    }

    func isConnected(_ service: CloudService) -> Bool {
        switch service {
        case .railway: return isRailwayConnected
        case .digitalOcean: return isDigitalOceanConnected
        case .openRouter: return isOpenRouterConnected
        }
    }

    /// Current-period spend for one service, or `nil` if it is not connected or has not loaded.
    func currentSpend(for service: CloudService) -> Double? {
        switch service {
        case .railway:
            return isRailwayConnected ? currentUsage : nil
        case .digitalOcean:
            return digitalOceanBalance?.monthToDateUsageValue
        case .openRouter:
            return openRouterAccount?.key.usageMonthly
        }
    }

    /// Sum of current-period spend across every connected service.
    var totalCurrentSpend: Double {
        CloudService.allCases.compactMap { currentSpend(for: $0) }.reduce(0, +)
    }

    func error(for service: CloudService) -> String? {
        switch service {
        case .railway: return railwayError
        case .digitalOcean: return digitalOceanError
        case .openRouter: return openRouterError
        }
    }

    // MARK: - Menu Bar Label

    var menuBarTitle: String {
        if showCostInMenuBar && hasAnyService {
            return String(format: "$%.2f", totalCurrentSpend)
        }
        return ""
    }

    // MARK: - Initialization

    private var hasInitialized = false

    /// Called once on first appearance. Loads any saved tokens from Keychain,
    /// restores the previously selected Railway workspace, and starts auto-refresh.
    func initialize() async {
        guard !hasInitialized else { return }
        hasInitialized = true

        await railwayAPI.loadTokenFromKeychain()
        await digitalOceanAPI.loadTokenFromKeychain()
        await openRouterAPI.loadTokenFromKeychain()

        isRailwayConnected = await railwayAPI.hasToken
        isDigitalOceanConnected = await digitalOceanAPI.hasToken
        isOpenRouterConnected = await openRouterAPI.hasToken

        if isRailwayConnected {
            selectedWorkspaceId = UserDefaults.standard.string(forKey: "selectedWorkspaceId")
        }

        if hasAnyService {
            await refreshAll()
        }
        startAutoRefresh()
    }

    // MARK: - Connecting services

    /// Validates the token against the service, saves it to Keychain, and loads initial data.
    func connect(_ service: CloudService, token: String) async throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        switch service {
        case .railway:
            await railwayAPI.setToken(trimmed)
            let workspaces = try await railwayAPI.validateTokenAndGetWorkspaces()
            if workspaces.isEmpty {
                throw RailwayAPIError.invalidToken
            }
            KeychainService.save(token: trimmed, for: .railway)
            self.workspaces = workspaces
            self.selectedWorkspaceId = workspaces.first?.id
            isRailwayConnected = true
            await refreshRailway()

        case .digitalOcean:
            await digitalOceanAPI.setToken(trimmed)
            let balance = try await digitalOceanAPI.fetchBalance()
            KeychainService.save(token: trimmed, for: .digitalOcean)
            digitalOceanBalance = balance
            isDigitalOceanConnected = true
            await refreshDigitalOcean()

        case .openRouter:
            await openRouterAPI.setToken(trimmed)
            let account = try await openRouterAPI.fetchAccount()
            KeychainService.save(token: trimmed, for: .openRouter)
            openRouterAccount = account
            isOpenRouterConnected = true
        }
        lastRefreshed = Date()
    }

    /// Deletes the stored token for the service and clears its data.
    func disconnect(_ service: CloudService) {
        KeychainService.delete(for: service)
        switch service {
        case .railway:
            isRailwayConnected = false
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
            railwayError = nil
            Task { await railwayAPI.setToken("") }
        case .digitalOcean:
            isDigitalOceanConnected = false
            digitalOceanBalance = nil
            digitalOceanInvoices = []
            digitalOceanError = nil
            Task { await digitalOceanAPI.setToken("") }
        case .openRouter:
            isOpenRouterConnected = false
            openRouterAccount = nil
            openRouterError = nil
            Task { await openRouterAPI.setToken("") }
        }
        if !hasAnyService {
            lastRefreshed = nil
        }
    }

    // MARK: - Data Refresh

    /// Refreshes every connected service concurrently.
    func refreshAll() async {
        guard hasAnyService else { return }
        isLoading = true

        async let railway: Void = isRailwayConnected ? refreshRailway() : ()
        async let digitalOcean: Void = isDigitalOceanConnected ? refreshDigitalOcean() : ()
        async let openRouter: Void = isOpenRouterConnected ? refreshOpenRouter() : ()
        _ = await (railway, digitalOcean, openRouter)

        lastRefreshed = Date()
        isLoading = false
    }

    /// Fetches Railway workspace billing details, projects, and recent deployments.
    /// If no workspace is selected, attempts to discover available workspaces first.
    func refreshRailway() async {
        guard let workspaceId = selectedWorkspaceId else {
            do {
                let workspaces = try await railwayAPI.validateTokenAndGetWorkspaces()
                self.workspaces = workspaces
                if let first = workspaces.first {
                    self.selectedWorkspaceId = first.id
                    await refreshRailway()
                }
            } catch {
                railwayError = error.localizedDescription
            }
            return
        }

        railwayError = nil

        do {
            let detail = try await railwayAPI.fetchWorkspaceDetail(workspaceId: workspaceId)
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
            railwayError = error.localizedDescription
        }

        do {
            let fetchedProjects = try await railwayAPI.fetchProjects(workspaceId: workspaceId)
            projects = fetchedProjects

            var allDeployments: [Deployment] = []
            for project in fetchedProjects {
                do {
                    let deployments = try await railwayAPI.fetchDeployments(projectId: project.id, limit: 5)
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
            if railwayError == nil {
                railwayError = error.localizedDescription
            }
        }
    }

    /// Fetches the DigitalOcean balance and recent invoices.
    func refreshDigitalOcean() async {
        digitalOceanError = nil
        do {
            digitalOceanBalance = try await digitalOceanAPI.fetchBalance()
        } catch {
            digitalOceanError = error.localizedDescription
            return
        }
        do {
            digitalOceanInvoices = try await digitalOceanAPI.fetchInvoices(limit: 3)
        } catch {
            // Invoices are supplementary. Keep the balance even if this fails.
        }
    }

    /// Fetches OpenRouter key usage and, when the key allows it, the credit balance.
    func refreshOpenRouter() async {
        openRouterError = nil
        do {
            openRouterAccount = try await openRouterAPI.fetchAccount()
        } catch {
            openRouterError = error.localizedDescription
        }
    }

    // MARK: - Auto Refresh

    /// Starts a background loop that calls ``refreshAll()`` at the user-configured interval.
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
