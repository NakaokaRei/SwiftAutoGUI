//
//  SampleApp.swift
//  Sample
//
//  Created by NakaokaRei on 2023/01/15.
//

import SwiftUI

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 700)
    }
}
