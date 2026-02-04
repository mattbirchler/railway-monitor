//
//  CostCard.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

/// Displays current-period usage cost, billing date range, and any available credit balance.
struct CostCard: View {
    let currentUsage: Double
    let creditBalance: Double
    let billingPeriodStart: Date?
    let billingPeriodEnd: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Period")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(formattedCost)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            if let start = billingPeriodStart, let end = billingPeriodEnd {
                Text("\(formatted(start)) - \(formatted(end))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if creditBalance > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                    Text("Credit: \(formattedCredit)")
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedCost: String {
        String(format: "$%.2f", currentUsage)
    }

    private var formattedCredit: String {
        String(format: "$%.2f", creditBalance)
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
