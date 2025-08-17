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
        let result = await Action.alert(
            "This is a sample alert message!",
            title: "SwiftAutoGUI Alert",
            button: "Got it!"
        ).execute() as? String
        alertResult = result
    }
    
    func showDefaultConfirm() async {
        let result = await Action.confirm(
            "Do you want to continue with the operation?",
            title: "Confirmation Required"
        ).execute() as? String
        confirmResult = result ?? "Cancelled"
    }
    
    func showCustomConfirm() async {
        let result = await Action.confirm(
            "What would you like to do next?",
            title: "Choose Action",
            buttons: ["Save", "Don't Save", "Cancel"]
        ).execute() as? String
        confirmResult = result ?? "Cancelled"
    }
    
    func showPrompt() async {
        let result = await Action.prompt(
            "Please enter your name:",
            title: "User Information",
            defaultAnswer: "John Doe"
        ).execute() as? String
        promptResult = result ?? "Cancelled"
    }
    
    func showPassword() async {
        let result = await Action.password(
            "Enter your password to continue:",
            title: "Authentication Required"
        ).execute() as? String
        passwordResult = result ?? "Cancelled"
    }
}