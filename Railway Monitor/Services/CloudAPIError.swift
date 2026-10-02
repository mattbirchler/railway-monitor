//
//  CloudAPIError.swift
//  Railway Monitor
//

import Foundation

/// Errors surfaced to the UI from the REST-based service clients.
nonisolated enum CloudAPIError: LocalizedError, Sendable {
    case noToken
    case invalidToken
    case forbidden
    case networkError(String)
    case httpError(Int, String?)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No API token configured."
        case .invalidToken:
            return "API token is invalid or expired."
        case .forbidden:
            return "This token does not have permission for that request."
        case .networkError(let message):
            return "Network error: \(message)"
        case .httpError(let code, let message):
            if let message, !message.isEmpty {
                return "HTTP \(code): \(message)"
            }
            return "HTTP \(code)"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

/// Shared JSON GET helper used by the REST clients.
nonisolated enum RESTClient {
    /// Performs an authenticated GET and decodes the JSON body.
    static func get<T: Decodable & Sendable>(
        _ url: URL,
        authorization: String,
        as type: T.Type = T.self
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CloudAPIError.networkError(error.localizedDescription)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        switch statusCode {
        case 200..<300:
            break
        case 401:
            throw CloudAPIError.invalidToken
        case 403:
            throw CloudAPIError.forbidden
        default:
            let body = String(data: data, encoding: .utf8)?.prefix(200)
            throw CloudAPIError.httpError(statusCode, body.map(String.init))
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CloudAPIError.decodingError(error.localizedDescription)
        }
    }
}
