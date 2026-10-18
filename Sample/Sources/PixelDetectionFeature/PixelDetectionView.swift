//
//  PixelDetectionView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct PixelDetectionView: View {
    public init() {}
    @State private var store = Store(initialState: PixelDetectionFeature.State()) {
        PixelDetectionFeature()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pixel Detection")
                .font(.headline)

            HStack {
                Button("Get Screen Size") {
                    store.send(.getScreenSize)
                }

                Button("Get Pixel Color at (100, 100)") {
                    store.send(.getPixelColor)
                }
            }

            if !store.screenSize.isEmpty {
                Text(store.screenSize)
                    .font(.caption)
            }

            if let color = store.pixelColor {
                HStack {
                    Text("Pixel color:")
                        .font(.caption)
                    Rectangle()
                        .fill(Color(color))
                        .frame(width: 30, height: 30)
                        .border(Color.black)
                }
            }
        }
        .onDisappear { store.send(.stop) }
    }
}
