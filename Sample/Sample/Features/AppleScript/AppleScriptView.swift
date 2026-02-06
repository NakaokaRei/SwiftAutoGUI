//
//  AppleScriptView.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/07/19.
//

import SwiftUI

struct AppleScriptView: View {
    @State private var viewModel = AppleScriptViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Label("AppleScript Execution", systemImage: "applescript")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Execute AppleScript code to automate macOS applications and system features.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            // Sample Scripts Menu
            HStack {
                Text("Sample Scripts:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Menu {
                    ForEach(AppleScriptViewModel.SampleScript.allCases, id: \.self) { sample in
                        Button(sample.rawValue) {
                            viewModel.loadSampleScript(sample)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                        Text("Load Sample")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
            }
            
            // Script Editor
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Script Editor", systemImage: "pencil.and.scribble")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if viewModel.isExecuting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                ScrollView {
                    TextEditor(text: $viewModel.scriptText)
                        .font(.custom("SF Mono", size: 13))
                        .padding(8)
                        .background(colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 200, maxHeight: 300)
                }
            }
            
            // Execute Button
            Button(action: {
                viewModel.executeScript()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Execute Script")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.isExecuting ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.isExecuting || viewModel.scriptText.isEmpty)
            
            // Result/Error Display
            if !viewModel.result.isEmpty || viewModel.errorMessage != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Error", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Result", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            
                            Text(viewModel.result)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.result)
                .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            }
            
            // Info Box
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("AppleScript execution may require additional permissions. Some scripts may prompt for access to control other applications.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
    }
}