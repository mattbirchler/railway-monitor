//
//  DigitalOceanAPI.swift
//  Railway Monitor
//

import Foundation

/// Client for the DigitalOcean REST API (v2). Reads billing information only.
actor DigitalOceanAPI {
    private let baseURL = URL(string: "https://api.digitalocean.com/v2")!
    private var token: String?

    func setToken(_ token: String) {
        self.token = token
    }

    func loadTokenFromKeychain() {
        self.token = KeychainService.retrieve(for: .digitalOcean)
    }

    var hasToken: Bool {
        !(token?.isEmpty ?? true)
    }

    private func authorization() throws -> String {
        guard let token, !token.isEmpty else { throw CloudAPIError.noToken }
        return "Bearer \(token)"
    }

    /// Fetches month-to-date usage and account balance. Also serves as token validation.
    func fetchBalance() async throws -> DigitalOceanBalance {
        let url = baseURL.appending(path: "customers/my/balance")
        return try await RESTClient.get(url, authorization: authorization())
    }

    /// Fetches the most recent invoices, newest first.
    func fetchInvoices(limit: Int = 3) async throws -> [DigitalOceanInvoice] {
        var components = URLComponents(url: baseURL.appending(path: "customers/my/invoices"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "per_page", value: String(limit))]
        let response: DigitalOceanInvoicesResponse = try await RESTClient.get(components.url!, authorization: authorization())
        return Array(response.invoices.prefix(limit))
    }
}
