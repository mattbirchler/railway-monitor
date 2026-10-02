//
//  DigitalOceanModels.swift
//  Railway Monitor
//

import Foundation

// Decodable models for the DigitalOcean REST API (v2). Monetary values arrive as strings.

/// Response from `GET /v2/customers/my/balance`.
nonisolated struct DigitalOceanBalance: Decodable, Sendable {
    let monthToDateUsage: String
    let accountBalance: String
    let monthToDateBalance: String
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case monthToDateUsage = "month_to_date_usage"
        case accountBalance = "account_balance"
        case monthToDateBalance = "month_to_date_balance"
        case generatedAt = "generated_at"
    }

    /// Spend so far in the current calendar month.
    var monthToDateUsageValue: Double { Double(monthToDateUsage) ?? 0 }

    /// Outstanding balance from the most recent invoice. Positive means money owed,
    /// negative means credit on the account.
    var accountBalanceValue: Double { Double(accountBalance) ?? 0 }

    var generatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: generatedAt)
    }
}

/// Response from `GET /v2/customers/my/invoices`.
nonisolated struct DigitalOceanInvoicesResponse: Decodable, Sendable {
    let invoices: [DigitalOceanInvoice]
}

nonisolated struct DigitalOceanInvoice: Identifiable, Decodable, Sendable {
    let invoiceUUID: String
    let invoiceID: String?
    let amount: String
    let invoicePeriod: String

    var id: String { invoiceUUID }

    enum CodingKeys: String, CodingKey {
        case invoiceUUID = "invoice_uuid"
        case invoiceID = "invoice_id"
        case amount
        case invoicePeriod = "invoice_period"
    }

    var amountValue: Double { Double(amount) ?? 0 }

    /// Formats the `YYYY-MM` period as a month name and year.
    var periodLabel: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM"
        guard let date = parser.date(from: invoicePeriod) else { return invoicePeriod }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
