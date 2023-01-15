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
                SwiftAutoGUI.keyDown(Keycode.control)
                SwiftAutoGUI.keyDown(Keycode.leftArrow)
                SwiftAutoGUI.keyUp(Keycode.leftArrow)
                SwiftAutoGUI.keyUp(Keycode.control)
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
