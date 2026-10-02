//
//  OpenRouterCard.swift
//  Railway Monitor
//

import SwiftUI

/// Shows OpenRouter spend for the current key over several windows, plus limits and credits when known.
struct OpenRouterCard: View {
    let account: OpenRouterAccount

    private var key: OpenRouterKeyInfo { account.key }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This Month")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "$%.2f", key.usageMonthly ?? 0))
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            HStack(spacing: 12) {
                stat("Today", key.usageDaily)
                stat("This week", key.usageWeekly)
                stat("All time", key.usage)
            }

            if let limit = key.limit {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle")
                        .font(.caption)
                    if let remaining = key.limitRemaining {
                        Text(String(format: "Key limit: $%.2f of $%.2f left", remaining, limit))
                            .font(.caption)
                    } else {
                        Text(String(format: "Key limit: $%.2f", limit))
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }

            if let credits = account.credits {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                    Text(String(format: "Credits: $%.2f left of $%.2f", credits.remaining, credits.totalCredits))
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

    private func stat(_ label: String, _ value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.2f", value ?? 0))
                .font(.caption.monospacedDigit())
        }
    }
}
