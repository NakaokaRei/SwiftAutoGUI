import AppKit

extension SwiftAutoGUI {
    
    /// Displays a simple alert dialog with a message.
    ///
    /// This function shows a modal alert dialog and waits for the user to dismiss it.
    /// The function blocks until the user clicks the button.
    ///
    /// - Parameters:
    ///   - text: The informative text to display in the alert. Defaults to empty string.
    ///   - title: The title of the alert dialog. Defaults to "Alert".
    ///   - button: The text for the dismiss button. Defaults to "OK".
    /// - Returns: The button text that was clicked (always returns the button parameter value).
    ///
    /// - Note: This function must be called from the main thread or within a Task/MainActor context.
    ///
    /// ## Example
    /// ```swift
    /// // Simple alert
    /// SwiftAutoGUI.alert("Operation completed!", title: "Success")
    ///
    /// // Custom button text
    /// SwiftAutoGUI.alert("File saved successfully", title: "Save Complete", button: "Great!")
    /// ```
    @MainActor
    @discardableResult
    public static func alert(
        _ text: String = "",
        title: String = "Alert",
        button: String = "OK"
    ) -> String {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.addButton(withTitle: button)
        alert.alertStyle = .informational
        
        alert.runModal()
        return button
    }
    
    /// Displays a confirmation dialog with customizable buttons.
    ///
    /// This function shows a modal confirmation dialog and waits for the user to click one of the buttons.
    /// It's useful for asking the user to make a choice or confirm an action.
    ///
    /// - Parameters:
    ///   - text: The informative text to display in the dialog. Defaults to empty string.
    ///   - title: The title of the confirmation dialog. Defaults to "Confirm".
    ///   - buttons: An array of button titles. Defaults to ["OK", "Cancel"].
    /// - Returns: The text of the button that was clicked, or `nil` if the dialog was dismissed without clicking a button.
    ///
    /// - Note: This function must be called from the main thread or within a Task/MainActor context.
    ///
    /// ## Example
    /// ```swift
    /// // Simple confirmation
    /// if let response = SwiftAutoGUI.confirm("Delete this file?") {
    ///     if response == "OK" {
    ///         // Delete the file
    ///     }
    /// }
    ///
    /// // Custom buttons
    /// if let response = SwiftAutoGUI.confirm(
    ///     "Save changes before closing?",
    ///     title: "Unsaved Changes",
    ///     buttons: ["Save", "Don't Save", "Cancel"]
    /// ) {
    ///     switch response {
    ///     case "Save":
    ///         // Save and close
    ///     case "Don't Save":
    ///         // Close without saving
    ///     case "Cancel":
    ///         // Cancel closing
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    @MainActor
    @discardableResult
    public static func confirm(
        _ text: String = "",
        title: String = "Confirm",
        buttons: [String] = ["OK", "Cancel"]
    ) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .warning
        
        for button in buttons {
            alert.addButton(withTitle: button)
        }
        
        let response = alert.runModal()
        let buttonIndex = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        
        if buttonIndex >= 0 && buttonIndex < buttons.count {
            return buttons[buttonIndex]
        }
        
        return nil
    }
    
    /// Displays a text input dialog.
    ///
    /// This function shows a modal dialog with a text field where the user can enter a string.
    /// It's useful for getting text input from the user during automation scripts.
    ///
    /// - Parameters:
    ///   - text: The informative text to display above the input field. Defaults to empty string.
    ///   - title: The title of the input dialog. Defaults to "Prompt".
    ///   - default: The default text to display in the input field. Defaults to empty string.
    /// - Returns: The text entered by the user, or `nil` if the dialog was cancelled.
    ///
    /// - Note: This function must be called from the main thread or within a Task/MainActor context.
    ///
    /// ## Example
    /// ```swift
    /// // Simple text input
    /// if let name = SwiftAutoGUI.prompt("Enter your name:") {
    ///     print("Hello, \(name)!")
    /// }
    ///
    /// // With default value
    /// if let email = SwiftAutoGUI.prompt(
    ///     "Please enter your email address:",
    ///     title: "Email Required",
    ///     default: "user@example.com"
    /// ) {
    ///     // Process email
    /// }
    /// ```
    @MainActor
    public static func prompt(
        _ text: String = "",
        title: String = "Prompt",
        default defaultValue: String = ""
    ) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = defaultValue
        alert.accessoryView = textField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            return textField.stringValue
        }
        
        return nil
    }
    
    /// Displays a secure password input dialog.
    ///
    /// This function shows a modal dialog with a secure text field where the user can enter a password.
    /// The input is masked for security, showing dots or asterisks instead of the actual characters.
    ///
    /// - Parameters:
    ///   - text: The informative text to display above the password field. Defaults to empty string.
    ///   - title: The title of the password dialog. Defaults to "Password".
    ///   - default: The default text to display in the password field. Defaults to empty string.
    ///   - mask: The character used to mask the password input. Defaults to "•". (Note: This parameter is included for API compatibility but the actual masking character is controlled by the system.)
    /// - Returns: The password entered by the user, or `nil` if the dialog was cancelled.
    ///
    /// - Note: This function must be called from the main thread or within a Task/MainActor context.
    /// - Important: The password is returned as plain text. Ensure you handle it securely in your application.
    ///
    /// ## Example
    /// ```swift
    /// // Simple password input
    /// if let password = SwiftAutoGUI.password("Enter your password:") {
    ///     // Use password securely
    /// }
    ///
    /// // With custom title and message
    /// if let adminPassword = SwiftAutoGUI.password(
    ///     "Admin access required. Please enter your administrator password:",
    ///     title: "Authentication Required"
    /// ) {
    ///     // Authenticate with admin password
    /// }
    /// ```
    @MainActor
    public static func password(
        _ text: String = "",
        title: String = "Password",
        default defaultValue: String = "",
        mask: Character = "•"
    ) -> String? {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let secureTextField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        secureTextField.stringValue = defaultValue
        alert.accessoryView = secureTextField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            return secureTextField.stringValue
        }
        
        return nil
    }
}