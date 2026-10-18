//
//  ImageRecognitionView.swift
//  Sample
//
//  Created by NakaokaRei on 2025/07/09.
//

import ComposableArchitecture
import SampleSupport
import SwiftUI

public struct ImageRecognitionView: View {
    public init() {}
    @State private var store = Store(initialState: ImageRecognitionFeature.State()) {
        ImageRecognitionFeature()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Image Recognition Features")
                .font(.headline)

            Button("Create Test Image") {
                store.send(.createTestImageForRecognition)
            }

            Button("Create Tiled Matcher Test Image") {
                store.send(.createTiledTestImageForRecognition)
            }

            Button("Locate Test Image on Screen") {
                store.send(.locateTestImage)
            }

            Button("Locate and Click Test Image") {
                store.send(.locateAndClickTestImage)
            }

            Button("Find All Test Images") {
                store.send(.findAllTestImages)
            }

            if !store.imageRecognitionResult.isEmpty {
                Text(store.imageRecognitionResult)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onDisappear { store.send(.stop) }
    }
}
