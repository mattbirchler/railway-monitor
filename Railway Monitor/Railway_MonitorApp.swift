//
//  Railway_MonitorApp.swift
//  Railway Monitor
//
//  Created by Matt Birchler on 2/3/26.
//

import SwiftUI

@main
struct Railway_MonitorApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
                .task {
                    await appState.initialize()
                }
        } label: {
            if appState.menuBarTitle.isEmpty {
                Image(systemName: "train.side.front.car")
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "train.side.front.car")
                    Text(appState.menuBarTitle)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
