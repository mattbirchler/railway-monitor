//
//  ProjectRow.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

/// Expandable row showing a project name, service count, and per-service deployment status.
struct ProjectRow: View {
    let project: Project
    let deployments: [Deployment]
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(project.services.edges, id: \.node.id) { edge in
                let service = edge.node
                HStack {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(service.name)
                        .font(.callout)

                    Spacer()

                    if let deployment = latestDeployment(for: service.name) {
                        DeploymentStatusBadge(status: deployment.status)
                    }
                }
                .padding(.leading, 8)
                .padding(.vertical, 2)
            }
        } label: {
            HStack {
                Image(systemName: "shippingbox")
                    .foregroundStyle(.secondary)
                Text(project.name)
                    .font(.callout.weight(.medium))
                Spacer()
                Text("\(project.services.edges.count) services")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func latestDeployment(for serviceName: String) -> Deployment? {
        deployments.first { $0.service?.name == serviceName }
    }
}
