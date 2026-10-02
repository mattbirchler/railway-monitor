//
//  ServiceSectionHeader.swift
//  Railway Monitor
//

import SwiftUI

/// Section heading for one service on the dashboard: icon, name, optional subtitle, and a dashboard link.
struct ServiceSectionHeader: View {
    let service: CloudService
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: service.symbolName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(service.displayName)
                .font(.subheadline.weight(.semibold))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Link(destination: service.dashboardURL) {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

/// Inline error banner used under a service section.
struct ServiceErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
