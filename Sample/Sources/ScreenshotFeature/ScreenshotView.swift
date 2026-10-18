//
//  ScreenshotView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct ScreenshotView: View {
    public init() {}
    @State private var store = Store(initialState: ScreenshotFeature.State()) {
        ScreenshotFeature()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Screenshot Features")
                .font(.headline)

            HStack {
                Button("Take Screenshot") {
                    store.send(.takeScreenshot)
                }

                Button("Screenshot Region (200x200)") {
                    store.send(.takeScreenshotRegion)
                }
            }

            HStack {
                Button("Save Screenshot to Documents") {
                    store.send(.saveScreenshotToDocuments)
                }

                Button("Save Region to Documents") {
                    store.send(.saveRegionToDocuments)
                }
            }

            if let image = store.screenshotImage {
                Text("Screenshot Preview:")
                    .font(.caption)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .border(Color.gray)
            }
        }
        .onDisappear { store.send(.stop) }
    }
}
