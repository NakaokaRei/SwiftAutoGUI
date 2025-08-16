//
//  ActionsDemoView.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/01/16.
//

import SwiftUI
import SwiftAutoGUI

struct ActionsDemoView: View {
    @StateObject private var viewModel = ActionsDemoViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Label("Action Pattern Demo", systemImage: "play.circle")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Execute predefined action sequences using the new Action pattern")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Example Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Example:")
                    .font(.headline)
                
                Picker("Example", selection: $viewModel.selectedExample) {
                    ForEach(ActionsDemoViewModel.ActionExample.allCases, id: \.self) { example in
                        Text(example.rawValue).tag(example)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200)
                
                Text(viewModel.selectedExample.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Action Preview
            GroupBox("Action Sequence") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(viewModel.selectedExample.actions.enumerated()), id: \.offset) { index, action in
                            HStack(spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                Text(viewModel.actionDescription(for: action))
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(index % 2 == 0 ? Color.secondary.opacity(0.05) : Color.clear)
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 150)
            }
            
            // Execute Button
            Button(action: {
                Task {
                    await viewModel.executeActions()
                }
            }) {
                Label("Execute Actions", systemImage: "play.circle.fill")
                    .frame(width: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isExecuting)
            
            // Execution Log
            GroupBox("Execution Log") {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.executionLog.isEmpty {
                                Text("No actions executed yet")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(Array(viewModel.executionLog.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .id(index)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: viewModel.executionLog.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.executionLog.count - 1, anchor: .bottom)
                        }
                    }
                }
                .frame(height: 150)
            }
            
            HStack {
                Button("Clear Log") {
                    viewModel.clearLog()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if viewModel.isExecuting {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Executing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(width: 600)
    }
}

struct ActionsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsDemoView()
    }
}