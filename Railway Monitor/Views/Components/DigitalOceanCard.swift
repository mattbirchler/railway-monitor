//
//  DigitalOceanCard.swift
//  Railway Monitor
//

import SwiftUI

/// Shows DigitalOcean month-to-date usage, outstanding balance, and recent invoices.
struct DigitalOceanCard: View {
    let balance: DigitalOceanBalance
    let invoices: [DigitalOceanInvoice]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Month to Date")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(String(format: "$%.2f", balance.monthToDateUsageValue))
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            if let generated = balance.generatedDate {
                Text("As of \(generated, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let accountBalance = balance.accountBalanceValue
            if accountBalance > 0.005 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                    Text(String(format: "Outstanding balance: $%.2f", accountBalance))
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            } else if accountBalance < -0.005 {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                    Text(String(format: "Credit: $%.2f", -accountBalance))
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }

            if !invoices.isEmpty {
                Divider()
                    .padding(.vertical, 2)
                ForEach(invoices) { invoice in
                    HStack {
                        Text(invoice.periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", invoice.amountValue))
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
