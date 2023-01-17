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
        VStack {
            Button("key event") {
                SwiftAutoGUI.keyDown(.control)
                SwiftAutoGUI.keyDown(.leftArrow)
                SwiftAutoGUI.keyUp(.leftArrow)
                SwiftAutoGUI.keyUp(.control)
            }
            Button("move mouse") {
                SwiftAutoGUI.moveMouse(dx: 10, dy: 10)
            }
            Button("click") {
                SwiftAutoGUI.leftClick()
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
