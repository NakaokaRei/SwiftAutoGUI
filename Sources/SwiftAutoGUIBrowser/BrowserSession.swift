import Foundation
import SwiftAutoGUI

/// A browser-only Agent backend connected to a Chromium debugging endpoint.
public actor BrowserSession: AgentAutomationBackend {
    public struct Options: Sendable {
        public var maxElements: Int
        public var actionObservationDelay: Duration

        public init(maxElements: Int = 100, actionObservationDelay: Duration = .milliseconds(200)) {
            self.maxElements = maxElements
            self.actionObservationDelay = actionObservationDelay
        }
    }

    private struct Discovery: Decodable {
        let webSocketDebuggerUrl: String
    }

    private let transport: any CDPTransporting
    private let securityPolicy: BrowserSecurityPolicy
    private let authorizer: (any BrowserActionAuthorizing)?
    private let options: Options
    private var eventTask: Task<Void, Never>?
    private var tabsByID: [String: BrowserTab] = [:]
    private var sessionIDByTabID: [String: String] = [:]
    private var activeTabID: String?
    private var observations: [UUID: BrowserObservation] = [:]
    private var pendingNavigation: AgentNavigationResult?
    private var pendingTabChanges: [AgentTabChange] = []
    private var pendingDownloads: [AgentDownloadResult] = []
    private var preauthorizedNavigationURLs: Set<String> = []

    init(
        transport: any CDPTransporting,
        securityPolicy: BrowserSecurityPolicy,
        authorizer: (any BrowserActionAuthorizing)?,
        options: Options
    ) {
        self.transport = transport
        self.securityPolicy = securityPolicy
        self.authorizer = authorizer
        self.options = options
    }

    /// Connects to an existing Chromium browser debugging endpoint.
    public static func connect(
        endpoint: URL,
        securityPolicy: BrowserSecurityPolicy = BrowserSecurityPolicy(),
        authorizer: (any BrowserActionAuthorizing)? = nil,
        options: Options = Options()
    ) async throws -> BrowserSession {
        try securityPolicy.validateEndpoint(endpoint)
        let discoveryURL = discoveryURL(for: endpoint)
        let delegate = DiscoverySessionDelegate(policy: securityPolicy)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let (data, response) = try await session.data(from: discoveryURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw BrowserError.discoveryFailed("GET \(discoveryURL.absoluteString) did not return HTTP 200.")
        }
        if let finalURL = response.url { try securityPolicy.validateEndpoint(finalURL) }
        let discovery: Discovery
        do { discovery = try JSONDecoder().decode(Discovery.self, from: data) }
        catch { throw BrowserError.discoveryFailed(error.localizedDescription) }
        guard let webSocketURL = URL(string: discovery.webSocketDebuggerUrl) else {
            throw BrowserError.invalidWebSocketURL(discovery.webSocketDebuggerUrl)
        }
        try securityPolicy.validateWebSocket(webSocketURL)

        let backend = BrowserSession(
            transport: WebSocketCDPTransport(webSocketURL: webSocketURL),
            securityPolicy: securityPolicy,
            authorizer: authorizer,
            options: options
        )
        try await backend.start()
        return backend
    }

    /// Closes the CDP connection.
    public func close() async {
        eventTask?.cancel()
        eventTask = nil
        await transport.close()
    }

    /// Returns all current page tabs.
    public func listTabs() async throws -> [BrowserTab] {
        try await refreshTabs()
        return sortedTabs()
    }

    /// Activates a page tab and makes it the target of subsequent observations.
    public func activateTab(_ tabID: String) async throws {
        try await refreshTabs()
        guard tabsByID[tabID] != nil else { throw BrowserError.tabNotFound(tabID) }
        _ = try await transport.send(
            method: "Target.activateTarget",
            params: .object(["targetId": .string(tabID)]),
            sessionID: nil
        )
        activeTabID = tabID
        try await ensureAttached(to: tabID)
        markActiveTab(tabID)
        pendingTabChanges.append(AgentTabChange(kind: .activated, tabID: tabID, url: tabsByID[tabID]?.url))
    }

    /// Observes the selected browser tab and builds a numbered semantic element map.
    public func observe(
        tabID requestedTabID: String? = nil,
        includeScreenshot: Bool = false
    ) async throws -> BrowserObservation {
        try await refreshTabs()
        guard let tabID = requestedTabID ?? activeTabID ?? sortedTabs().first?.id else {
            throw BrowserError.noPageTabs
        }
        if activeTabID != tabID { try await activateTab(tabID) }
        try await ensureAttached(to: tabID)
        guard let sessionID = sessionIDByTabID[tabID], var tab = tabsByID[tabID] else {
            throw BrowserError.tabNotFound(tabID)
        }

        _ = try await transport.send(
            method: "DOM.getDocument",
            params: .object(["depth": .number(3), "pierce": .bool(true)]),
            sessionID: sessionID
        )
        let frameTree = try await transport.send(
            method: "Page.getFrameTree",
            params: .object([:]),
            sessionID: sessionID
        )
        guard let frame = frameTree["frameTree"]?["frame"],
              let frameID = frame["id"]?.stringValue else {
            throw BrowserError.malformedResponse("Page.getFrameTree omitted the main frame.")
        }
        let loaderID = frame["loaderId"]?.stringValue ?? "same-document"
        let observedURL = frame["url"]?.stringValue ?? tab.url
        tab = BrowserTab(id: tab.id, url: observedURL, title: tab.title, state: tab.state)
        tabsByID[tabID] = tab

        var candidates: [BrowserAXCandidate] = []
        for observedFrameID in frameIDs(from: frameTree["frameTree"]) where candidates.count < options.maxElements {
            let axTree = try await transport.send(
                method: "Accessibility.getFullAXTree",
                params: .object(["frameId": .string(observedFrameID)]),
                sessionID: sessionID
            )
            candidates.append(
                contentsOf: BrowserSelectorMapBuilder.candidates(
                    from: axTree,
                    limit: options.maxElements - candidates.count
                )
            )
        }
        var bounds: [Int: BrowserRect] = [:]
        var destinationURLs: [Int: String] = [:]
        for candidate in candidates {
            let params = CDPJSONValue.object(
                ("backendNodeId", .number(Double(candidate.backendDOMNodeID)))
            )
            if let box = try? await transport.send(method: "DOM.getBoxModel", params: params, sessionID: sessionID),
               let rect = BrowserSelectorMapBuilder.bounds(from: box) {
                bounds[candidate.backendDOMNodeID] = rect
            }
            if let description = try? await transport.send(
                method: "DOM.describeNode",
                params: .object(["backendNodeId": .number(Double(candidate.backendDOMNodeID)), "depth": .number(0)]),
                sessionID: sessionID
            ), let url = BrowserSelectorMapBuilder.destinationURL(from: description) {
                destinationURLs[candidate.backendDOMNodeID] = url
            }
        }
        let elements = BrowserSelectorMapBuilder.elements(
            candidates: candidates,
            bounds: bounds,
            destinationURLs: destinationURLs
        )
        let viewport = try await viewportSize(sessionID: sessionID)
        let screenshot = includeScreenshot ? try await captureScreenshot(sessionID: sessionID) : nil
        let allTabs = sortedTabs()
        let formatted = BrowserSelectorMapBuilder.format(tabs: allTabs, activeTabID: tabID, elements: elements)
        let fingerprint = BrowserSelectorMapBuilder.fingerprint(tab: tab, loaderID: loaderID, elements: elements)
        let observation = BrowserObservation(
            tab: tab,
            frameID: frameID,
            loaderID: loaderID,
            viewportSize: viewport,
            elements: elements,
            formattedContext: formatted,
            stateFingerprint: fingerprint,
            screenshotJPEGData: screenshot
        )
        observations[observation.id] = observation
        trimObservations()
        return observation
    }

    /// Executes a browser action against the exact observation that produced it.
    public func execute(
        _ action: BrowserAction,
        against observation: BrowserObservation
    ) async -> BrowserActionResult {
        pendingNavigation = nil
        pendingTabChanges.removeAll()
        pendingDownloads.removeAll()
        do {
            try await perform(action, against: observation)
            if options.actionObservationDelay > .zero {
                try await Task.sleep(for: options.actionObservationDelay)
            }
            let next = try await observe(tabID: activeTabID, includeScreenshot: false)
            return BrowserActionResult(
                action: action,
                succeeded: true,
                observation: next,
                navigation: pendingNavigation,
                tabChanges: pendingTabChanges,
                downloads: pendingDownloads
            )
        } catch {
            let failure = (error as? BrowserError) ?? .malformedResponse(error.localizedDescription)
            let next = (try? await observe(tabID: activeTabID, includeScreenshot: false)) ?? observation
            return BrowserActionResult(
                action: action,
                succeeded: false,
                failure: failure,
                observation: next,
                navigation: pendingNavigation,
                tabChanges: pendingTabChanges,
                downloads: pendingDownloads
            )
        }
    }

    // MARK: AgentAutomationBackend

    public func observe(visionMode: AgentVisionMode) async throws -> AgentObservation {
        var browserObservation = try await observe(tabID: activeTabID, includeScreenshot: visionMode == .always)
        if visionMode == .automatic, browserObservation.elements.isEmpty {
            browserObservation = try await observe(tabID: browserObservation.tab.id, includeScreenshot: true)
        }
        return makeAgentObservation(browserObservation)
    }

    public func execute(
        _ action: BasicAction,
        in observation: AgentObservation
    ) async -> AgentAutomationExecution {
        guard observation.kind == .browser,
              let browserObservation = observations[observation.id] else {
            let result = ActionExecutionResult(
                action: action,
                succeeded: false,
                method: .none,
                failureReason: BrowserError.observationNotFound.localizedDescription
            )
            return AgentAutomationExecution(result: result, observation: observation)
        }

        guard let browserAction = browserAction(from: action) else {
            let error = BrowserError.unsupportedAction(String(describing: action))
            let result = ActionExecutionResult(
                action: action,
                succeeded: false,
                method: .none,
                failureReason: error.localizedDescription
            )
            return AgentAutomationExecution(result: result, observation: observation)
        }

        let browserResult = await execute(browserAction, against: browserObservation)
        let changed = browserObservation.stateFingerprint != browserResult.observation.stateFingerprint
            || browserResult.navigation != nil
            || !browserResult.tabChanges.isEmpty
            || !browserResult.downloads.isEmpty
        let result = ActionExecutionResult(
            action: action,
            succeeded: browserResult.succeeded,
            method: .cdp,
            failureReason: browserResult.failure?.localizedDescription,
            screenChanged: changed,
            navigation: browserResult.navigation,
            tabChanges: browserResult.tabChanges,
            downloads: browserResult.downloads
        )
        return AgentAutomationExecution(
            result: result,
            observation: makeAgentObservation(browserResult.observation)
        )
    }

    // MARK: Connection and events

    func start() async throws {
        try await transport.connect()
        let stream = await transport.events()
        eventTask = Task { [weak self] in
            for await event in stream {
                await self?.handle(event)
            }
        }
        _ = try await transport.send(method: "Browser.getVersion", params: .object([:]), sessionID: nil)
        _ = try await transport.send(
            method: "Target.setDiscoverTargets",
            params: .object(["discover": .bool(true)]),
            sessionID: nil
        )
        _ = try? await transport.send(
            method: "Browser.setDownloadBehavior",
            params: .object(["behavior": .string("default"), "eventsEnabled": .bool(true)]),
            sessionID: nil
        )
        try await refreshTabs()
        guard let first = sortedTabs().first else { throw BrowserError.noPageTabs }
        activeTabID = first.id
        try await ensureAttached(to: first.id)
        markActiveTab(first.id)
    }

    private func refreshTabs() async throws {
        let result = try await transport.send(method: "Target.getTargets", params: .object([:]), sessionID: nil)
        let infos = result["targetInfos"]?.arrayValue ?? []
        var refreshed: [String: BrowserTab] = [:]
        for info in infos where info["type"]?.stringValue == "page" {
            guard let id = info["targetId"]?.stringValue else { continue }
            let existing = tabsByID[id]
            let state: BrowserTabState = id == activeTabID ? .active : (existing?.state ?? .ready)
            refreshed[id] = BrowserTab(
                id: id,
                url: info["url"]?.stringValue ?? "",
                title: info["title"]?.stringValue ?? "",
                state: state
            )
        }
        tabsByID = refreshed
        if let activeTabID, tabsByID[activeTabID] == nil { self.activeTabID = sortedTabs().first?.id }
    }

    private func ensureAttached(to tabID: String) async throws {
        if sessionIDByTabID[tabID] != nil { return }
        let result = try await transport.send(
            method: "Target.attachToTarget",
            params: .object(["targetId": .string(tabID), "flatten": .bool(true)]),
            sessionID: nil
        )
        guard let sessionID = result["sessionId"]?.stringValue else {
            throw BrowserError.malformedResponse("Target.attachToTarget omitted sessionId.")
        }
        sessionIDByTabID[tabID] = sessionID
        for method in ["Page.enable", "DOM.enable", "Accessibility.enable"] {
            _ = try await transport.send(method: method, params: .object([:]), sessionID: sessionID)
        }
        _ = try await transport.send(
            method: "Page.setLifecycleEventsEnabled",
            params: .object(["enabled": .bool(true)]),
            sessionID: sessionID
        )
        _ = try await transport.send(
            method: "Fetch.enable",
            params: .object([
                "patterns": .array([
                    .object([
                        "urlPattern": .string("*"),
                        "resourceType": .string("Document"),
                        "requestStage": .string("Request")
                    ])
                ])
            ]),
            sessionID: sessionID
        )
    }

    private func handle(_ event: CDPEvent) async {
        switch event.method {
        case "Target.targetCreated":
            guard let info = event.params["targetInfo"], info["type"]?.stringValue == "page",
                  let id = info["targetId"]?.stringValue else { return }
            let tab = BrowserTab(
                id: id,
                url: info["url"]?.stringValue ?? "",
                title: info["title"]?.stringValue ?? "",
                state: .ready
            )
            tabsByID[id] = tab
            pendingTabChanges.append(.init(kind: .opened, tabID: id, url: tab.url))

        case "Target.targetDestroyed":
            guard let id = event.params["targetId"]?.stringValue else { return }
            let url = tabsByID[id]?.url
            tabsByID[id] = nil
            sessionIDByTabID[id] = nil
            pendingTabChanges.append(.init(kind: .closed, tabID: id, url: url))

        case "Target.targetInfoChanged":
            guard let info = event.params["targetInfo"], info["type"]?.stringValue == "page",
                  let id = info["targetId"]?.stringValue else { return }
            let old = tabsByID[id]
            tabsByID[id] = BrowserTab(
                id: id,
                url: info["url"]?.stringValue ?? old?.url ?? "",
                title: info["title"]?.stringValue ?? old?.title ?? "",
                state: old?.state ?? .ready
            )

        case "Page.frameStartedLoading":
            updateTabState(for: event.sessionID, state: .loading)

        case "Page.frameStoppedLoading", "Page.loadEventFired":
            updateTabState(for: event.sessionID, state: .ready)

        case "Page.frameNavigated":
            guard let frame = event.params["frame"], frame["parentId"] == nil,
                  let url = frame["url"]?.stringValue,
                  let tabID = tabID(for: event.sessionID), let old = tabsByID[tabID] else { return }
            tabsByID[tabID] = BrowserTab(id: old.id, url: url, title: old.title, state: .ready)
            if old.url != url { pendingNavigation = .init(fromURL: old.url, toURL: url) }

        case "Fetch.requestPaused":
            await handlePausedRequest(event)

        case "Browser.downloadWillBegin":
            await handleDownloadWillBegin(event.params)

        case "Browser.downloadProgress":
            handleDownloadProgress(event.params)

        default:
            break
        }
    }

    private func handlePausedRequest(_ event: CDPEvent) async {
        guard let requestID = event.params["requestId"]?.stringValue,
              let value = event.params["request"]?["url"]?.stringValue,
              let url = URL(string: value) else { return }
        let allowed = securityPolicy.allowsNavigation(to: url)
        var authorized = allowed
        if allowed, preauthorizedNavigationURLs.remove(url.absoluteString) == nil {
            let currentURL = tabID(for: event.sessionID)
                .flatMap { tabsByID[$0] }
                .flatMap { URL(string: $0.url) }
            if isCrossOrigin(from: currentURL, to: url) {
                authorized = await authorizer?.authorize(.crossOriginNavigation(from: currentURL, to: url)) ?? false
            }
        }
        let method = authorized ? "Fetch.continueRequest" : "Fetch.failRequest"
        var params: [String: CDPJSONValue] = ["requestId": .string(requestID)]
        if !authorized { params["errorReason"] = .string("BlockedByClient") }
        _ = try? await transport.send(method: method, params: .object(params), sessionID: event.sessionID)
    }

    private func handleDownloadWillBegin(_ params: CDPJSONValue) async {
        guard let guid = params["guid"]?.stringValue else { return }
        let url = params["url"]?.stringValue.flatMap(URL.init(string:))
        let filename = params["suggestedFilename"]?.stringValue
        let allowed = await authorizer?.authorize(.download(url: url, suggestedFilename: filename)) ?? false
        pendingDownloads.append(
            .init(
                identifier: guid,
                url: url?.absoluteString,
                suggestedFilename: filename,
                state: allowed ? .requested : .canceled
            )
        )
        if !allowed {
            _ = try? await transport.send(
                method: "Browser.cancelDownload",
                params: .object(["guid": .string(guid)]),
                sessionID: nil
            )
        }
    }

    private func handleDownloadProgress(_ params: CDPJSONValue) {
        guard let guid = params["guid"]?.stringValue,
              let stateValue = params["state"]?.stringValue else { return }
        let state: AgentDownloadResult.State = switch stateValue {
        case "completed": .completed
        case "canceled": .canceled
        default: .inProgress
        }
        pendingDownloads.append(
            .init(identifier: guid, state: state, filePath: params["filePath"]?.stringValue)
        )
    }

    // MARK: Action execution

    private func perform(_ action: BrowserAction, against observation: BrowserObservation) async throws {
        switch action {
        case .navigate(let url):
            try await authorizeNavigation(from: URL(string: observation.tab.url), to: url)
            preauthorizedNavigationURLs.insert(url.absoluteString)
            guard let sessionID = sessionIDByTabID[observation.tab.id] else {
                throw BrowserError.tabNotFound(observation.tab.id)
            }
            let result = try await transport.send(
                method: "Page.navigate",
                params: .object(["url": .string(url.absoluteString)]),
                sessionID: sessionID
            )
            if let errorText = result["errorText"]?.stringValue, !errorText.isEmpty {
                throw BrowserError.malformedResponse(errorText)
            }

        case .click(let elementID):
            let element = try await resolveElement(elementID, in: observation)
            if let destination = resolvedDestination(element.destinationURL, base: observation.tab.url) {
                try await authorizeNavigation(from: URL(string: observation.tab.url), to: destination)
                preauthorizedNavigationURLs.insert(destination.absoluteString)
            }
            guard let sessionID = sessionIDByTabID[observation.tab.id] else {
                throw BrowserError.tabNotFound(observation.tab.id)
            }
            _ = try? await transport.send(
                method: "DOM.scrollIntoViewIfNeeded",
                params: .object(["backendNodeId": .number(Double(element.backendDOMNodeID))]),
                sessionID: sessionID
            )
            let live = try await resolveElement(elementID, in: observation)
            for (type, button) in [("mouseMoved", "none"), ("mousePressed", "left"), ("mouseReleased", "left")] {
                _ = try await transport.send(
                    method: "Input.dispatchMouseEvent",
                    params: .object([
                        "type": .string(type),
                        "x": .number(live.bounds.midX),
                        "y": .number(live.bounds.midY),
                        "button": .string(button),
                        "clickCount": .number(type == "mouseMoved" ? 0 : 1)
                    ]),
                    sessionID: sessionID
                )
            }

        case .replaceText(let elementID, let value):
            let element = try await resolveElement(elementID, in: observation)
            guard element.isEditable else { throw BrowserError.unsupportedAction("text replacement for #\(elementID)") }
            guard let sessionID = sessionIDByTabID[observation.tab.id] else {
                throw BrowserError.tabNotFound(observation.tab.id)
            }
            _ = try await transport.send(
                method: "DOM.focus",
                params: .object(["backendNodeId": .number(Double(element.backendDOMNodeID))]),
                sessionID: sessionID
            )
            try await dispatchShortcut(["command", "a"], sessionID: sessionID)
            _ = try await transport.send(
                method: "Input.insertText",
                params: .object(["text": .string(value)]),
                sessionID: sessionID
            )

        case .insertText(let text):
            guard let sessionID = activeSessionID else { throw BrowserError.noPageTabs }
            _ = try await transport.send(
                method: "Input.insertText",
                params: .object(["text": .string(text)]),
                sessionID: sessionID
            )

        case .keyShortcut(let keys):
            guard let sessionID = activeSessionID else { throw BrowserError.noPageTabs }
            try await dispatchShortcut(keys, sessionID: sessionID)

        case .scroll(let horizontal, let vertical):
            guard let sessionID = activeSessionID else { throw BrowserError.noPageTabs }
            _ = try await transport.send(
                method: "Input.dispatchMouseEvent",
                params: .object([
                    "type": .string("mouseWheel"),
                    "x": .number(observation.viewportSize.width / 2),
                    "y": .number(observation.viewportSize.height / 2),
                    "deltaX": .number(Double(horizontal) * 100),
                    "deltaY": .number(Double(-vertical) * 100)
                ]),
                sessionID: sessionID
            )

        case .activateTab(let tabID):
            try await activateTab(tabID)

        case .wait(let duration):
            guard duration >= 0 else { throw BrowserError.unsupportedAction("negative wait") }
            try await Task.sleep(for: .seconds(duration))
        }
    }

    private func resolveElement(_ elementID: Int, in observation: BrowserObservation) async throws -> BrowserElement {
        guard activeTabID == observation.tab.id,
              let observed = observation.element(withID: elementID),
              let sessionID = sessionIDByTabID[observation.tab.id] else {
            throw BrowserError.staleElement(elementID)
        }
        let frameTree = try await transport.send(method: "Page.getFrameTree", params: .object([:]), sessionID: sessionID)
        let currentLoader = frameTree["frameTree"]?["frame"]?["loaderId"]?.stringValue ?? "same-document"
        guard currentLoader == observation.loaderID else { throw BrowserError.staleElement(elementID) }

        let partial = try await transport.send(
            method: "Accessibility.getPartialAXTree",
            params: .object([
                "backendNodeId": .number(Double(observed.backendDOMNodeID)),
                "fetchRelatives": .bool(false)
            ]),
            sessionID: sessionID
        )
        guard let candidate = BrowserSelectorMapBuilder.candidates(from: partial, limit: 1).first,
              candidate.role == observed.role,
              candidate.name == observed.name,
              candidate.isEnabled else { throw BrowserError.staleElement(elementID) }
        let box = try await transport.send(
            method: "DOM.getBoxModel",
            params: .object(["backendNodeId": .number(Double(observed.backendDOMNodeID))]),
            sessionID: sessionID
        )
        guard let bounds = BrowserSelectorMapBuilder.bounds(from: box), bounds.width > 0, bounds.height > 0 else {
            throw BrowserError.staleElement(elementID)
        }
        return BrowserElement(
            elementID: observed.elementID,
            backendDOMNodeID: observed.backendDOMNodeID,
            frameID: candidate.frameID,
            role: candidate.role,
            name: candidate.name,
            value: candidate.value,
            bounds: bounds,
            isEnabled: candidate.isEnabled,
            isEditable: candidate.isEditable,
            destinationURL: observed.destinationURL
        )
    }

    private func dispatchShortcut(_ keys: [String], sessionID: String) async throws {
        let normalized = keys.map { $0.lowercased() }
        let modifiers = normalized.reduce(0) { result, key in
            let bit = switch key {
            case "option", "alt": 1
            case "control", "ctrl": 2
            case "command", "cmd", "meta": 4
            case "shift": 8
            default: 0
            }
            return result | bit
        }
        let modifierNames: Set<String> = ["option", "alt", "control", "ctrl", "command", "cmd", "meta", "shift"]
        guard let keyName = normalized.last(where: { !modifierNames.contains($0) }) else {
            throw BrowserError.unsupportedAction("key shortcut with no non-modifier key")
        }
        let mapped = mapKey(keyName)
        let common: [String: CDPJSONValue] = [
            "modifiers": .number(Double(modifiers)),
            "key": .string(mapped.key),
            "code": .string(mapped.code),
            "windowsVirtualKeyCode": .number(Double(mapped.virtualKeyCode))
        ]
        for type in ["rawKeyDown", "keyUp"] {
            var params = common
            params["type"] = .string(type)
            _ = try await transport.send(
                method: "Input.dispatchKeyEvent",
                params: .object(params),
                sessionID: sessionID
            )
        }
    }

    // MARK: Helpers

    private func browserAction(from action: BasicAction) -> BrowserAction? {
        switch action {
        case .pressElement(let id): .click(elementID: id)
        case .setElementValue(let id, let value): .replaceText(elementID: id, value: value)
        case .write(let text): .insertText(text)
        case .keyShortcut(let keys): .keyShortcut(keys)
        case .vscroll(let clicks): .scroll(horizontal: 0, vertical: clicks)
        case .hscroll(let clicks): .scroll(horizontal: clicks, vertical: 0)
        case .wait(let duration): .wait(duration)
        case .openURL(let value): URL(string: value).map(BrowserAction.navigate)
        case .activateTab(let tabID): .activateTab(tabID)
        default: nil
        }
    }

    private func makeAgentObservation(_ observation: BrowserObservation) -> AgentObservation {
        observations[observation.id] = observation
        return AgentObservation(
            id: observation.id,
            kind: .browser,
            formattedContext: observation.formattedContext,
            stateFingerprint: observation.stateFingerprint,
            actionableElementCount: observation.elements.count,
            viewportSize: observation.viewportSize,
            screenshotJPEGData: observation.screenshotJPEGData
        )
    }

    private func authorizeNavigation(from: URL?, to: URL) async throws {
        guard securityPolicy.allowsNavigation(to: to) else {
            throw BrowserError.navigationNotAllowed(to.absoluteString)
        }
        if isCrossOrigin(from: from, to: to) {
            let allowed = await authorizer?.authorize(.crossOriginNavigation(from: from, to: to)) ?? false
            guard allowed else { throw BrowserError.authorizationDenied("navigation to \(to.absoluteString)") }
        }
    }

    private func isCrossOrigin(from: URL?, to: URL) -> Bool {
        guard let from else { return true }
        return origin(of: from) != origin(of: to)
    }

    private func origin(of url: URL) -> String {
        "\(url.scheme?.lowercased() ?? "")://\(url.host?.lowercased() ?? ""):\(url.port ?? defaultPort(for: url))"
    }

    private func defaultPort(for url: URL) -> Int { url.scheme?.lowercased() == "https" ? 443 : 80 }

    private func resolvedDestination(_ value: String?, base: String) -> URL? {
        guard let value else { return nil }
        return URL(string: value, relativeTo: URL(string: base))?.absoluteURL
    }

    private func viewportSize(sessionID: String) async throws -> CGSize {
        let result = try await transport.send(method: "Page.getLayoutMetrics", params: .object([:]), sessionID: sessionID)
        let viewport = result["cssVisualViewport"] ?? result["visualViewport"]
        let width = viewport?["clientWidth"]?.doubleValue ?? 1024
        let height = viewport?["clientHeight"]?.doubleValue ?? 768
        return CGSize(width: width, height: height)
    }

    private func captureScreenshot(sessionID: String) async throws -> Data {
        let result = try await transport.send(
            method: "Page.captureScreenshot",
            params: .object(["format": .string("jpeg"), "quality": .number(50), "fromSurface": .bool(true)]),
            sessionID: sessionID
        )
        guard let encoded = result["data"]?.stringValue,
              let data = Data(base64Encoded: encoded) else {
            throw BrowserError.malformedResponse("Page.captureScreenshot omitted image data.")
        }
        return data
    }

    private func sortedTabs() -> [BrowserTab] {
        tabsByID.values.sorted { lhs, rhs in
            if lhs.id == activeTabID { return true }
            if rhs.id == activeTabID { return false }
            return lhs.id < rhs.id
        }
    }

    private func markActiveTab(_ id: String) {
        for (tabID, tab) in tabsByID {
            let state: BrowserTabState = tabID == id ? .active : (tab.state == .loading ? .loading : .ready)
            tabsByID[tabID] = BrowserTab(id: tab.id, url: tab.url, title: tab.title, state: state)
        }
    }

    private func updateTabState(for sessionID: String?, state: BrowserTabState) {
        guard let tabID = tabID(for: sessionID), let tab = tabsByID[tabID] else { return }
        let effectiveState: BrowserTabState = state == .ready && tabID == activeTabID ? .active : state
        tabsByID[tabID] = BrowserTab(id: tab.id, url: tab.url, title: tab.title, state: effectiveState)
    }

    private func tabID(for sessionID: String?) -> String? {
        guard let sessionID else { return nil }
        return sessionIDByTabID.first { $0.value == sessionID }?.key
    }

    private var activeSessionID: String? {
        activeTabID.flatMap { sessionIDByTabID[$0] }
    }

    private func trimObservations() {
        guard observations.count > 20 else { return }
        let keep = Set(observations.keys.suffix(20))
        observations = observations.filter { keep.contains($0.key) }
    }

    private func frameIDs(from frameTree: CDPJSONValue?) -> [String] {
        guard let frameTree else { return [] }
        var ids: [String] = []
        if let id = frameTree["frame"]?["id"]?.stringValue { ids.append(id) }
        for child in frameTree["childFrames"]?.arrayValue ?? [] {
            ids.append(contentsOf: frameIDs(from: child))
        }
        return ids
    }

    private func mapKey(_ name: String) -> (key: String, code: String, virtualKeyCode: Int) {
        if name.count == 1, let scalar = name.uppercased().unicodeScalars.first {
            let upper = name.uppercased()
            return (upper.lowercased(), "Key\(upper)", Int(scalar.value))
        }
        return switch name {
        case "returnkey", "return", "enter": ("Enter", "Enter", 13)
        case "space": (" ", "Space", 32)
        case "tab": ("Tab", "Tab", 9)
        case "escape": ("Escape", "Escape", 27)
        case "delete", "backspace": ("Backspace", "Backspace", 8)
        case "uparrow": ("ArrowUp", "ArrowUp", 38)
        case "downarrow": ("ArrowDown", "ArrowDown", 40)
        case "leftarrow": ("ArrowLeft", "ArrowLeft", 37)
        case "rightarrow": ("ArrowRight", "ArrowRight", 39)
        default: (name, name, 0)
        }
    }

    private static func discoveryURL(for endpoint: URL) -> URL {
        if endpoint.path.hasSuffix("/json/version") { return endpoint }
        return endpoint.appending(path: "json/version")
    }
}

private final class DiscoverySessionDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let policy: BrowserSecurityPolicy

    init(policy: BrowserSecurityPolicy) { self.policy = policy }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        guard let url = request.url, (try? policy.validateEndpoint(url)) != nil else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}
