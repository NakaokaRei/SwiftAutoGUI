//
//  ContentView.swift
//  Sample
//
//  Created by NakaokaRei on 2023/01/15.
//

import SwiftUI
import SwiftAutoGUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            ForEach(0..<10) {
                Text("\($0)").font(.title)
            }
            Button("key event") {
                SwiftAutoGUI.sendKeyShortcut([.control, .leftArrow])
            }
            Button("special key event") {
                SwiftAutoGUI.keyDown(.soundUp)
                SwiftAutoGUI.keyUp(.soundUp)
            }
            Button("move mouse") {
                SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
            }
            Button("click") {
                SwiftAutoGUI.leftClick()
            }
            Button("vscroll -") {
                SwiftAutoGUI.vscroll(clicks: -1)
            }
            Button("vscroll +") {
                SwiftAutoGUI.vscroll(clicks: 1)
            }
            ForEach(0..<10) {
                Text("\($0)").font(.title)
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0..<10) {
                        Text("\($0)").font(.title)
                    }
                    Button("hscroll -") {
                        SwiftAutoGUI.hscroll(clicks: -1)
                    }
                    Button("hscroll +") {
                        SwiftAutoGUI.hscroll(clicks: 1)
                    }
                    ForEach(0..<10) {
                        Text("\($0)").font(.title)
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
