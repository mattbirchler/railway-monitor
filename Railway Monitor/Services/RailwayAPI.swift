//
//  RailwayAPI.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import Foundation
import os

private let logger = Logger(subsystem: "com.birchtree.Railway-Monitor", category: "API")

/// Errors surfaced to the UI from API operations.
nonisolated enum RailwayAPIError: LocalizedError, Sendable {
    case noToken
    case invalidToken
    case networkError(String)
    case graphQLErrors([String])
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No API token configured."
        case .invalidToken:
            return "API token is invalid or expired."
        case .networkError(let message):
            return "Network error: \(message)"
        case .graphQLErrors(let messages):
            return messages.joined(separator: "\n")
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

/// Handles all communication with the Railway GraphQL API (v2).
/// Declared as an `actor` to ensure the stored token is accessed safely across tasks.
actor RailwayAPI {
    private let endpoint = URL(string: "https://backboard.railway.com/graphql/v2")!
    private var token: String?

    func setToken(_ token: String) {
        self.token = token
    }

    func loadTokenFromKeychain() {
        self.token = KeychainService.retrieve()
    }

    var hasToken: Bool {
        token != nil && !(token?.isEmpty ?? true)
    }

    // MARK: - Token Validation & Workspace Discovery

    func validateTokenAndGetWorkspaces() async throws -> [Workspace] {
        let query = """
        {
            apiToken {
                workspaces {
                    id
                    name
                }
            }
        }
        """
        let response: GraphQLResponse<APITokenResponse> = try await execute(query: query)
        guard let data = response.data else {
            throw RailwayAPIError.invalidToken
        }
        return data.apiToken.workspaces
    }

    // MARK: - Workspace Billing

    func fetchWorkspaceDetail(workspaceId: String) async throws -> WorkspaceDetail {
        let query = """
        query WorkspaceDetail($workspaceId: String!) {
            workspace(workspaceId: $workspaceId) {
                name
                plan
                customer {
                    currentUsage
                    creditBalance
                    billingPeriod {
                        start
                        end
                    }
                    state
                }
            }
        }
        """
        let variables = ["workspaceId": workspaceId]
        let response: GraphQLResponse<WorkspaceDetailResponse> = try await execute(query: query, variables: variables)
        guard let data = response.data else {
            if let errors = response.errors {
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }
            throw RailwayAPIError.invalidToken
        }
        return data.workspace
    }

    // MARK: - Projects

    func fetchProjects(workspaceId: String) async throws -> [Project] {
        let query = """
        query Projects($workspaceId: String!) {
            projects(workspaceId: $workspaceId) {
                edges {
                    node {
                        id
                        name
                        services {
                            edges {
                                node {
                                    id
                                    name
                                }
                            }
                        }
                        environments {
                            edges {
                                node {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        let variables = ["workspaceId": workspaceId]
        let response: GraphQLResponse<ProjectsResponse> = try await execute(query: query, variables: variables)
        guard let data = response.data else {
            if let errors = response.errors {
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }
            throw RailwayAPIError.invalidToken
        }
        return data.projects.edges.map(\.node)
    }

    // MARK: - Deployments

    func fetchDeployments(projectId: String, limit: Int = 5) async throws -> [Deployment] {
        let query = """
        query Deployments($input: DeploymentListInput!) {
            deployments(input: $input) {
                edges {
                    node {
                        id
                        status
                        createdAt
                        service {
                            name
                        }
                    }
                }
            }
        }
        """
        let variables: [String: Any] = [
            "input": [
                "projectId": projectId,
                "first": limit
            ]
        ]
        let response: GraphQLResponse<DeploymentsResponse> = try await execute(query: query, variables: variables)
        guard let data = response.data else {
            if let errors = response.errors {
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }
            return []
        }
        return data.deployments.edges.map(\.node)
    }

    // MARK: - Service Instance

    func fetchServiceInstance(serviceId: String, environmentId: String) async throws -> ServiceInstance {
        let query = """
        query ServiceInstance($serviceId: String!, $environmentId: String!) {
            serviceInstance(serviceId: $serviceId, environmentId: $environmentId) {
                latestDeployment {
                    id
                    status
                    createdAt
                }
            }
        }
        """
        let variables = ["serviceId": serviceId, "environmentId": environmentId]
        let response: GraphQLResponse<ServiceInstanceResponse> = try await execute(query: query, variables: variables)
        guard let data = response.data else {
            if let errors = response.errors {
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }
            throw RailwayAPIError.graphQLErrors(["Failed to fetch service instance"])
        }
        return data.serviceInstance
    }

    // MARK: - GraphQL Execution

    /// Sends a GraphQL query to the Railway API and decodes the response into the given type.
    private func execute<T: Decodable & Sendable>(query: String, variables: [String: Any]? = nil) async throws -> GraphQLResponse<T> {
        guard let token = token, !token.isEmpty else {
            throw RailwayAPIError.noToken
        }

        var body: [String: Any] = ["query": query]
        if let variables = variables {
            body["variables"] = variables
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        logger.debug("➡️ Sending GraphQL request")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logger.error("❌ NETWORK ERROR: \(error.localizedDescription)")
            throw RailwayAPIError.networkError(error.localizedDescription)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        logger.debug("⬅️ Response received (HTTP \(statusCode))")

        if statusCode == 401 {
            throw RailwayAPIError.invalidToken
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(GraphQLResponse<T>.self, from: data)

            if let errors = result.errors, result.data == nil {
                logger.warning("⚠️ GRAPHQL ERRORS: \(errors.map(\.message).joined(separator: ", "))")
                throw RailwayAPIError.graphQLErrors(errors.map(\.message))
            }

            return result
        } catch let error as RailwayAPIError {
            throw error
        } catch {
            logger.error("❌ DECODE ERROR: \(error.localizedDescription)")
            throw RailwayAPIError.decodingError(error.localizedDescription)
        }
    }
}
