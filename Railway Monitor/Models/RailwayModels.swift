//
//  RailwayModels.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation

// MARK: - GraphQL Response Wrappers

nonisolated struct GraphQLResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T?
    let errors: [GraphQLError]?
}

nonisolated struct GraphQLError: Decodable, Sendable {
    let message: String
}

// MARK: - API Token / Workspace Discovery

nonisolated struct APITokenResponse: Decodable, Sendable {
    let apiToken: APIToken
}

nonisolated struct APIToken: Decodable, Sendable {
    let workspaces: [Workspace]
}

nonisolated struct Workspace: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
}

// MARK: - Workspace Detail / Billing

nonisolated struct WorkspaceDetailResponse: Decodable, Sendable {
    let workspace: WorkspaceDetail
}

nonisolated struct WorkspaceDetail: Decodable, Sendable {
    let name: String
    let plan: String
    let customer: Customer
}

nonisolated struct Customer: Decodable, Sendable {
    let currentUsage: Double
    let creditBalance: Double
    let billingPeriod: BillingPeriod
    let state: String?
}

nonisolated struct BillingPeriod: Decodable, Sendable {
    let start: String
    let end: String
}

// MARK: - Projects

nonisolated struct ProjectsResponse: Decodable, Sendable {
    let projects: ProjectConnection
}

nonisolated struct ProjectConnection: Decodable, Sendable {
    let edges: [ProjectEdge]
}

nonisolated struct ProjectEdge: Decodable, Sendable {
    let node: Project
}

nonisolated struct Project: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
    let services: ServiceConnection
    let environments: EnvironmentConnection
}

nonisolated struct ServiceConnection: Decodable, Sendable {
    let edges: [ServiceEdge]
}

nonisolated struct ServiceEdge: Decodable, Sendable {
    let node: Service
}

nonisolated struct Service: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
}

nonisolated struct EnvironmentConnection: Decodable, Sendable {
    let edges: [EnvironmentEdge]
}

nonisolated struct EnvironmentEdge: Decodable, Sendable {
    let node: RailwayEnvironment
}

nonisolated struct RailwayEnvironment: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
}

// MARK: - Deployments

nonisolated struct DeploymentsResponse: Decodable, Sendable {
    let deployments: DeploymentConnection
}

nonisolated struct DeploymentConnection: Decodable, Sendable {
    let edges: [DeploymentEdge]
}

nonisolated struct DeploymentEdge: Decodable, Sendable {
    let node: Deployment
}

nonisolated struct Deployment: Identifiable, Decodable, Sendable {
    let id: String
    let status: DeploymentStatus
    let createdAt: String
    let service: DeploymentService?

    var createdDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: createdAt)
    }

    var timeAgo: String {
        guard let date = createdDate else { return createdAt }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

nonisolated struct DeploymentService: Decodable, Sendable {
    let name: String
}

nonisolated enum DeploymentStatus: String, Decodable, CaseIterable, Sendable {
    case SUCCESS
    case BUILDING
    case DEPLOYING
    case INITIALIZING
    case FAILED
    case CRASHED
    case SLEEPING
    case REMOVED
    case SKIPPED
    case WAITING
    case QUEUED
    case NEEDS_APPROVAL

    var displayName: String {
        switch self {
        case .SUCCESS: return "Success"
        case .BUILDING: return "Building"
        case .DEPLOYING: return "Deploying"
        case .INITIALIZING: return "Initializing"
        case .FAILED: return "Failed"
        case .CRASHED: return "Crashed"
        case .SLEEPING: return "Sleeping"
        case .REMOVED: return "Removed"
        case .SKIPPED: return "Skipped"
        case .WAITING: return "Waiting"
        case .QUEUED: return "Queued"
        case .NEEDS_APPROVAL: return "Needs Approval"
        }
    }
}

// MARK: - Service Instance

nonisolated struct ServiceInstanceResponse: Decodable, Sendable {
    let serviceInstance: ServiceInstance
}

nonisolated struct ServiceInstance: Decodable, Sendable {
    let latestDeployment: LatestDeployment?
}

nonisolated struct LatestDeployment: Identifiable, Decodable, Sendable {
    let id: String
    let status: DeploymentStatus
    let createdAt: String
}
