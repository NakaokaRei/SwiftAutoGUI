import Foundation

struct CDPEvent: Sendable, Equatable {
    let method: String
    let params: CDPJSONValue
    let sessionID: String?
}

protocol CDPTransporting: Sendable {
    func connect() async throws
    func send(
        method: String,
        params: CDPJSONValue,
        sessionID: String?
    ) async throws -> CDPJSONValue
    func events() async -> AsyncStream<CDPEvent>
    func close() async
}

actor WebSocketCDPTransport: CDPTransporting {
    private struct Command: Encodable {
        let id: Int
        let method: String
        let params: CDPJSONValue
        let sessionId: String?
    }

    private struct ErrorPayload: Decodable {
        let code: Int
        let message: String
    }

    private struct Incoming: Decodable {
        let id: Int?
        let method: String?
        let params: CDPJSONValue?
        let result: CDPJSONValue?
        let error: ErrorPayload?
        let sessionId: String?
    }

    private struct Pending {
        let method: String
        let continuation: CheckedContinuation<CDPJSONValue, Error>
    }

    private let webSocketURL: URL
    private let commandTimeout: Duration
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var nextID = 1
    private var pending: [Int: Pending] = [:]
    private var eventContinuations: [UUID: AsyncStream<CDPEvent>.Continuation] = [:]
    private var isClosed = false

    init(
        webSocketURL: URL,
        commandTimeout: Duration = .seconds(10),
        session: URLSession = .shared
    ) {
        self.webSocketURL = webSocketURL
        self.commandTimeout = commandTimeout
        self.session = session
    }

    func connect() async throws {
        guard task == nil else { return }
        isClosed = false
        let task = session.webSocketTask(with: webSocketURL)
        self.task = task
        task.resume()
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func send(
        method: String,
        params: CDPJSONValue = .object([:]),
        sessionID: String? = nil
    ) async throws -> CDPJSONValue {
        guard let task, !isClosed else { throw BrowserError.disconnected }
        let id = nextID
        nextID += 1
        let command = Command(id: id, method: method, params: params, sessionId: sessionID)
        let data = try JSONEncoder().encode(command)
        guard let text = String(data: data, encoding: .utf8) else {
            throw BrowserError.malformedResponse("Could not encode command \(method).")
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[id] = Pending(method: method, continuation: continuation)
                Task { [weak self] in
                    do {
                        try await task.send(.string(text))
                    } catch {
                        await self?.failRequest(id: id, error: error)
                    }
                }
                Task { [weak self, commandTimeout] in
                    try? await Task.sleep(for: commandTimeout)
                    await self?.timeOutRequest(id: id)
                }
            }
        } onCancel: {
            Task { [weak self] in
                await self?.failRequest(id: id, error: CancellationError())
            }
        }
    }

    func events() -> AsyncStream<CDPEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            eventContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeEventContinuation(id) }
            }
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        let requests = pending.values
        pending.removeAll()
        for request in requests {
            request.continuation.resume(throwing: BrowserError.disconnected)
        }
        for continuation in eventContinuations.values { continuation.finish() }
        eventContinuations.removeAll()
    }

    private func receiveLoop() async {
        guard let task else { return }
        do {
            while !Task.isCancelled {
                let message = try await task.receive()
                let data: Data
                switch message {
                case .data(let value): data = value
                case .string(let value): data = Data(value.utf8)
                @unknown default: continue
                }
                let incoming = try JSONDecoder().decode(Incoming.self, from: data)
                handle(incoming)
            }
        } catch is CancellationError {
            return
        } catch {
            close()
        }
    }

    private func handle(_ incoming: Incoming) {
        if let id = incoming.id, let request = pending.removeValue(forKey: id) {
            if let error = incoming.error {
                request.continuation.resume(
                    throwing: BrowserError.protocolError(code: error.code, message: error.message)
                )
            } else {
                request.continuation.resume(returning: incoming.result ?? .object([:]))
            }
            return
        }
        guard let method = incoming.method else { return }
        let event = CDPEvent(
            method: method,
            params: incoming.params ?? .object([:]),
            sessionID: incoming.sessionId
        )
        for continuation in eventContinuations.values { continuation.yield(event) }
    }

    private func failRequest(id: Int, error: Error) {
        pending.removeValue(forKey: id)?.continuation.resume(throwing: error)
    }

    private func timeOutRequest(id: Int) {
        guard let request = pending.removeValue(forKey: id) else { return }
        request.continuation.resume(throwing: BrowserError.timeout(method: request.method))
    }

    private func removeEventContinuation(_ id: UUID) {
        eventContinuations.removeValue(forKey: id)
    }
}
