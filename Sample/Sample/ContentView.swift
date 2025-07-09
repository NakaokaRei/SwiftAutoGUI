//
//  ContentView.swift
//  Sample
//
//  Created by NakaokaRei on 2023/01/15.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = DemoTab.keyboard
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(DemoTab.allCases, id: \.self) { tab in
                        TabButton(
                            title: tab.title,
                            icon: tab.icon,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Content area
            ScrollView {
                Group {
                    switch selectedTab {
                    case .keyboard:
                        KeyboardDemoView()
                    case .mouse:
                        MouseControlView()
                    case .textTyping:
                        TextTypingView()
                    case .screenshot:
                        ScreenshotView()
                    case .imageRecognition:
                        ImageRecognitionView()
                    case .pixelDetection:
                        PixelDetectionView()
                    case .scrolling:
                        ScrollingDemoView()
                    }
                }
                .padding()
                .animation(.easeInOut, value: selectedTab)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
