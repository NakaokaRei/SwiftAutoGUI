import Foundation

enum InputTestConfiguration {
    static let isEnabled =
        ProcessInfo.processInfo.environment["SWIFTAUTOGUI_RUN_INPUT_TESTS"] == "1"
}
