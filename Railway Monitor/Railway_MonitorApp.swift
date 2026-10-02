//
//  Railway_MonitorApp.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

/// App entry point. Renders a menu bar extra (popover window) with a spend gauge icon.
/// Optionally displays the combined current-period cost next to the icon.
@main
struct Railway_MonitorApp: App {
    @State private var appState = AppState()

    /// Provider-neutral menu bar icon, since the app monitors several cloud services.
    private static let menuBarSymbol = "dollarsign.gauge.chart.lefthalf.righthalf"

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .task {
                    await appState.initialize()
                }
        } label: {
            if appState.menuBarTitle.isEmpty {
                Image(systemName: Self.menuBarSymbol)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: Self.menuBarSymbol)
                    Text(appState.menuBarTitle)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
