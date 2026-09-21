import Foundation

extension BasicAction {
    /// Validate generated or decoded parameters before any side effect.
    public func validate() throws {
        func require(_ condition: Bool, _ detail: String) throws {
            guard condition else { throw ActionGeneratorError.invalidResponse(detail: detail) }
        }
        func nonempty(_ value: String) -> Bool {
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        switch self {
        case .move(let x, let y):
            try require(x.isFinite && y.isFinite, "Mouse coordinates must be finite.")
        case .drag(let x, let y, let tx, let ty):
            try require([x, y, tx, ty].allSatisfy(\.isFinite), "Drag coordinates must be finite.")
        case .wait(let duration):
            try require(duration.isFinite && duration >= 0 && duration < Double(UInt64.max) / 1_000_000_000,
                        "Wait duration must be finite, nonnegative, and representable in nanoseconds.")
        case .vscroll(let clicks), .hscroll(let clicks):
            try require(Int32(exactly: clicks) != nil, "Scroll amount exceeds the supported range.")
        case .keyShortcut(let keys):
            try require(!keys.isEmpty, "A keyboard shortcut must contain at least one key.")
        case .pressButton(let label, _):
            try require(nonempty(label), "A button label is required.")
        case .selectMenuItem(let path, _):
            try require(!path.isEmpty && path.allSatisfy(nonempty), "A nonempty menu path is required.")
        case .raiseWindow(let title, _):
            try require(nonempty(title), "A window title is required.")
        case .pressElement(let id), .setElementValue(let id, _):
            try require(id > 0, "Element IDs must come from the current observation.")
        case .activateTab(let id):
            try require(nonempty(id), "A browser tab ID is required.")
        case .openURL(let value):
            try require(validatedHTTPURL(value) != nil, "An absolute HTTP or HTTPS URL with a host is required.")
        case .activateApp(let name), .quitApp(let name):
            try require(normalizedAppName(name) != nil, "A valid application name, not a path, is required.")
        default: break
        }
    }
}
