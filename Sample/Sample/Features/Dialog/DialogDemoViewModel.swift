//
//  DialogDemoViewModel.swift
//  Sample
//
//  Created by SwiftAutoGUI on 2025/07/12.
//

import Foundation
import SwiftAutoGUI

@MainActor
class DialogDemoViewModel: ObservableObject {
    @Published var alertResult: String?
    @Published var confirmResult: String?
    @Published var promptResult: String?
    @Published var passwordResult: String?
    
    func showAlert() async {
        let result = SwiftAutoGUI.alert(
            "This is a sample alert message!",
            title: "SwiftAutoGUI Alert",
            button: "Got it!"
        )
        alertResult = result
    }
    
    func showDefaultConfirm() async {
        let result = SwiftAutoGUI.confirm(
            "Do you want to continue with the operation?",
            title: "Confirmation Required"
        )
        confirmResult = result ?? "Cancelled"
    }
    
    func showCustomConfirm() async {
        let result = SwiftAutoGUI.confirm(
            "What would you like to do next?",
            title: "Choose Action",
            buttons: ["Save", "Don't Save", "Cancel"]
        )
        confirmResult = result ?? "Cancelled"
    }
    
    func showPrompt() async {
        let result = SwiftAutoGUI.prompt(
            "Please enter your name:",
            title: "User Information",
            default: "John Doe"
        )
        promptResult = result ?? "Cancelled"
    }
    
    func showPassword() async {
        let result = SwiftAutoGUI.password(
            "Enter your password to continue:",
            title: "Authentication Required"
        )
        passwordResult = result ?? "Cancelled"
    }
}