//
//  DeploymentStatusBadge.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

struct DeploymentStatusBadge: View {
    let status: DeploymentStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay {
                    if isActive {
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                }

            Text(status.displayName)
                .font(.caption)
                .foregroundStyle(color)
        }
    }

    private var color: Color {
        switch status {
        case .SUCCESS:
            return .green
        case .BUILDING, .DEPLOYING, .INITIALIZING:
            return .orange
        case .FAILED, .CRASHED:
            return .red
        case .SLEEPING:
            return .gray
        case .REMOVED, .SKIPPED:
            return .gray.opacity(0.6)
        case .WAITING, .QUEUED, .NEEDS_APPROVAL:
            return .yellow
        }
    }

    private var isActive: Bool {
        switch status {
        case .BUILDING, .DEPLOYING, .INITIALIZING:
            return true
        default:
            return false
        }
    }
}
