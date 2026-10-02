//
//  SetupView.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

/// First-run view. Lets the user pick a cloud service and enter its credential.
struct SetupView: View {
    @State private var selectedService: CloudService?

    var body: some View {
        if let service = selectedService {
            ConnectServiceView(
                service: service,
                onConnected: { selectedService = nil },
                onCancel: { selectedService = nil }
            )
        } else {
            servicePicker
        }
    }

    private var servicePicker: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Railway Monitor")
                .font(.headline)

            Text("Pick a service to connect. You can add more later in Settings.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(CloudService.allCases) { service in
                    Button {
                        selectedService = service
                    } label: {
                        HStack {
                            Image(systemName: service.symbolName)
                                .frame(width: 20)
                            Text(service.displayName)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
        .frame(width: 280)
    }
}
