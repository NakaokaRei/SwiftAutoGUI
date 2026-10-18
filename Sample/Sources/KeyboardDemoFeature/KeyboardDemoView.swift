//
//  KeyboardDemoView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct KeyboardDemoView: View {
    public init() {}
    @State private var store = Store(initialState: KeyboardDemoFeature.State()) {
        KeyboardDemoFeature()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard Demo")
                .font(.headline)

            Button("Key Shortcut (⌃←)") {
                store.send(.sendKeyShortcut)
            }

            Button("Special Key (Volume Up)") {
                store.send(.sendSpecialKeyEvent)
            }
        }
        .onDisappear { store.send(.stop) }
    }
}
