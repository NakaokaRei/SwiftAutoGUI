//
//  ContentView.swift
//  Sample
//
//  Created by NakaokaRei on 2023/01/15.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = DemoTab.keyboard
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "command.square.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SwiftAutoGUI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Automation Demo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Tab selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DemoTab.allCases, id: \.self) { tab in
                            TabButton(
                                title: tab.title,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 16)
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.black.opacity(0.3)
                    } else {
                        Color.white
                    }
                    
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.05),
                            Color.purple.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            
            // Content area
            ScrollView {
                VStack {
                    Group {
                        switch selectedTab {
                        case .keyboard:
                            KeyboardDemoView()
                        case .keyboardLayout:
                            KeyboardLayoutView()
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
                        case .dialog:
                            DialogDemoView()
                        case .appleScript:
                            AppleScriptView()
                        case .actions:
                            ActionsDemoView()
                        case .aiGeneration:
                            AIGenerationDemoView()
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    )
                    .padding(20)
                }
            }
            .background(colorScheme == .dark ? Color.black.opacity(0.5) : Color.gray.opacity(0.1))
        }
        .frame(width: 900, height: 700)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
