import Foundation
import Network

/// A WebSocket client that manages a socket connection.
open class NWWebSocket: WebSocketConnection {

    // MARK: - Public properties

    /// The WebSocket connection delegate.
    public weak var delegate: WebSocketConnectionDelegate?

    /// The default `NWProtocolWebSocket.Options` for a WebSocket connection.
    ///
    /// These options specify that the connection automatically replies to Ping messages
    /// instead of delivering them to the `receiveMessage(data:context:)` method.
    public static var defaultOptions: NWProtocolWebSocket.Options {
        let options = NWProtocolWebSocket.Options()
        options.autoReplyPing = true

        return options
    }

    private let errorWhileWaitingLimit = 20

    // MARK: - Private properties

    private var connection: NWConnection?
    private let endpoint: NWEndpoint
    private let parameters: NWParameters
    private let connectionQueue: DispatchQueue
    private var pingTimer: Timer?
    private let disconnectionQueue = DispatchQueue(label: "nwwebsocket.disconnection")
    private var disconnectionWorkItem: DispatchWorkItem?
    private var isMigratingConnection = false
    private var errorWhileWaitingCount = 0

    // MARK: - Initialization

    /// Creates a `NWWebSocket` instance which connects to a socket `url` with some configuration `options`.
    /// - Parameters:
    ///   - request: The `URLRequest` containing the connection endpoint `URL`.
    ///   - connectAutomatically: Determines if a connection should occur automatically on initialization.
    ///                           The default value is `false`.
    ///   - options: The configuration options for the connection. The default value is `NWWebSocket.defaultOptions`.
    ///   - connectionQueue: A `DispatchQueue` on which to deliver all connection events. The default value is `.main`.
    public convenience init(request: URLRequest,
                            connectAutomatically: Bool = false,
                            options: NWProtocolWebSocket.Options = NWWebSocket.defaultOptions,
                            connectionQueue: DispatchQueue = .main) {

        guard let url = request.url else {
            // If URLRequest has no URL, create a placeholder that will immediately fail
            // This prevents a crash and allows proper error handling
            let invalidURL = URL(string: "ws://invalid.url")!
            self.init(url: invalidURL,
                      connectAutomatically: connectAutomatically,
                      options: options,
                      connectionQueue: connectionQueue)
            return
        }

        self.init(url: url,
                  connectAutomatically: connectAutomatically,
                  options: options,
                  connectionQueue: connectionQueue)
    }

    /// Creates a `NWWebSocket` instance which connects a socket `url` with some configuration `options`.
    /// - Parameters:
    ///   - url: The connection endpoint `URL`.
    ///   - connectAutomatically: Determines if a connection should occur automatically on initialization.
    ///                           The default value is `false`.
    ///   - options: The configuration options for the connection. The default value is `NWWebSocket.defaultOptions`.
    ///   - connectionQueue: A `DispatchQueue` on which to deliver all connection events. The default value is `.main`.
    public init(url: URL,
                connectAutomatically: Bool = false,
                options: NWProtocolWebSocket.Options = NWWebSocket.defaultOptions,
                connectionQueue: DispatchQueue = .main) {

        endpoint = .url(url)

        if url.scheme == "ws" {
            parameters = NWParameters.tcp
        } else {
            parameters = NWParameters.tls
        }

        parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

        self.connectionQueue = connectionQueue

        if connectAutomatically {
            connect()
        }
    }

    deinit {
        let localConnection = connection

        // Clear all handlers before cancelling to prevent race conditions
        localConnection?.intentionalDisconnection = true
        localConnection?.stateUpdateHandler = nil
        localConnection?.betterPathUpdateHandler = nil
        localConnection?.viabilityUpdateHandler = nil

        // Cancel on a background queue with delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            localConnection?.cancel()
        }
    }

    // MARK: - WebSocketConnection conformance

    /// Connect to the WebSocket.
    open func connect() {
        if connection == nil {
            connection = NWConnection(to: endpoint, using: parameters)
            connection?.stateUpdateHandler = { [weak self] state in
                self?.stateDidChange(to: state)
            }
            connection?.betterPathUpdateHandler = { [weak self] isAvailable in
                self?.betterPath(isAvailable: isAvailable)
            }
            connection?.viabilityUpdateHandler = { [weak self] isViable in
                self?.viabilityDidChange(isViable: isViable)
            }
            listen()
            connection?.start(queue: connectionQueue)
        } else if let conn = connection, !isMigratingConnection {
            // Only start if the connection is in a state that allows starting
            switch conn.state {
            case .setup:
                // Connection exists but hasn't been started yet
                conn.start(queue: connectionQueue)
            case .cancelled, .failed:
                // Connection is dead - don't try to start it
                // Let the stateDidChange handler deal with cleanup
                break
            case .ready, .preparing, .waiting:
                // Connection is already started or connected - do nothing
                break
            @unknown default:
                // Handle unknown states safely
                break
            }
        }
    }

    /// Send a UTF-8 formatted `String` over the WebSocket.
    /// - Parameter string: The `String` that will be sent.
    open func send(string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext",
                                                  metadata: [metadata])

        send(data: data, context: context)
    }

    /// Send some `Data` over the WebSocket.
    /// - Parameter data: The `Data` that will be sent.
    open func send(data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "binaryContext",
                                                  metadata: [metadata])

        send(data: data, context: context)
    }

    /// Start listening for messages over the WebSocket.
    public func listen() {
        connection?.receiveMessage { [weak self] (data, context, _, error) in
            guard let self = self else {
                return
            }

            if let data = data, !data.isEmpty, let context = context {
                self.receiveMessage(data: data, context: context)
            }

            if let error = error {
                self.reportErrorOrDisconnection(error)
            } else {
                self.listen()
            }
        }
    }

    /// Ping the WebSocket periodically.
    /// - Parameter interval: The `TimeInterval` (in seconds) with which to ping the server.
    open func ping(interval: TimeInterval) {
        // Invalidate any existing timer to prevent memory leaks
        pingTimer?.invalidate()

        pingTimer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.ping()
        }
        pingTimer?.tolerance = 0.01
    }

    /// Ping the WebSocket once.
    open func ping() {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
        metadata.setPongHandler(connectionQueue) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.reportErrorOrDisconnection(error)
            } else {
                self.delegate?.webSocketDidReceivePong(connection: self)
            }
        }
        let context = NWConnection.ContentContext(identifier: "pingContext",
                                                  metadata: [metadata])

        send(data: "ping".data(using: .utf8), context: context)
    }

    /// Disconnect from the WebSocket.
    /// - Parameter closeCode: The code to use when closing the WebSocket connection.
    open func disconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {
        connection?.intentionalDisconnection = true

        // Call `cancel()` directly for a `normalClosure`
        // (Otherwise send the custom closeCode as a message).
        if closeCode == .protocolCode(.normalClosure) {
            connection?.cancel()
            scheduleDisconnectionReporting(closeCode: closeCode,
                                           reason: nil)
        } else {
            let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
            metadata.closeCode = closeCode
            let context = NWConnection.ContentContext(identifier: "closeContext",
                                                      metadata: [metadata])

            if connection?.state == .ready {
                // See implementation of `send(data:context:)` for `scheduleDisconnection(closeCode:, reason:)`
                send(data: nil, context: context)
            } else {
                scheduleDisconnectionReporting(closeCode: closeCode, reason: nil)
            }
        }
    }

    // MARK: - Private methods

    // MARK: Connection state changes

    /// The handler for managing changes to the `connection.state` via the `stateUpdateHandler` on a `NWConnection`.
    /// - Parameter state: The new `NWConnection.State`
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .ready:
            isMigratingConnection = false
            delegate?.webSocketDidConnect(connection: self)
        case .waiting(let error):
            isMigratingConnection = false
            reportErrorOrDisconnection(error)

            /// Workaround to prevent loop while reconnecting
            errorWhileWaitingCount += 1
            if errorWhileWaitingCount >= errorWhileWaitingLimit {
                tearDownConnection(error: error)
                errorWhileWaitingCount = 0
            }
        case .failed(let error):
            errorWhileWaitingCount = 0
            isMigratingConnection = false
            tearDownConnection(error: error)
        case .setup, .preparing:
            break
        case .cancelled:
            errorWhileWaitingCount = 0
            tearDownConnection(error: nil)
        @unknown default:
            // Handle unknown states gracefully - treat as a failure condition
            errorWhileWaitingCount = 0
            isMigratingConnection = false
            let unknownStateError = NWError.posix(.ECONNABORTED)
            tearDownConnection(error: unknownStateError)
        }
    }

    /// The handler for informing the `delegate` if there is a better network path available
    /// - Parameter isAvailable: `true` if a better network path is available.
    private func betterPath(isAvailable: Bool) {
        if isAvailable {
            migrateConnection { [weak self] result in
                guard let self = self else {
                    return
                }

                self.delegate?.webSocketDidAttemptBetterPathMigration(result: result)
            }
        }
    }

    /// The handler for informing the `delegate` if the network connection viability has changed.
    /// - Parameter isViable: `true` if the network connection is viable.
    private func viabilityDidChange(isViable: Bool) {
        delegate?.webSocketViabilityDidChange(connection: self, isViable: isViable)
    }

    /// Attempts to migrate the active `connection` to a new one.
    ///
    /// Migrating can be useful if the active `connection` detects that a better network path has become available.
    /// - Parameter completionHandler: Returns a `Result`with the new connection if the migration was successful
    /// or a `NWError` if the migration failed for some reason.
    private func migrateConnection(completionHandler: @escaping (Result<WebSocketConnection, NWError>) -> Void) {
        guard !isMigratingConnection else {
            completionHandler(.failure(NWError.posix(.EALREADY)))
            return
        }

        isMigratingConnection = true

        let oldConnection = connection
        oldConnection?.intentionalDisconnection = true

        // Clear all handlers before cancelling to prevent race conditions
        oldConnection?.stateUpdateHandler = nil
        oldConnection?.betterPathUpdateHandler = nil
        oldConnection?.viabilityUpdateHandler = nil

        connection = NWConnection(to: endpoint, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            self.stateDidChange(to: state)

            // Call completion handler based on connection state
            switch state {
            case .ready:
                completionHandler(.success(self))
            case .failed(let error):
                completionHandler(.failure(error))
            default:
                break
            }
        }
        connection?.betterPathUpdateHandler = { [weak self] isAvailable in
            self?.betterPath(isAvailable: isAvailable)
        }
        connection?.viabilityUpdateHandler = { [weak self] isViable in
            self?.viabilityDidChange(isViable: isViable)
        }
        listen()
        connection?.start(queue: connectionQueue)

        // cancel the old connection after new one is set up
        connectionQueue.asyncAfter(deadline: .now() + 0.1) {
            oldConnection?.cancel()
        }
    }

    // MARK: Connection data transfer

    /// Receive a WebSocket message, and handle it according to it's metadata.
    /// - Parameters:
    ///   - data: The `Data` that was received in the message.
    ///   - context: `ContentContext` representing the received message, and its metadata.
    private func receiveMessage(data: Data, context: NWConnection.ContentContext) {
        guard let metadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata else {
            return
        }

        switch metadata.opcode {
        case .binary:
            self.delegate?.webSocketDidReceiveMessage(connection: self,
                                                      data: data)
        case .cont:
            //
            break
        case .text:
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            self.delegate?.webSocketDidReceiveMessage(connection: self,
                                                      string: string)
        case .close:
            scheduleDisconnectionReporting(closeCode: metadata.closeCode,
                                           reason: data)
        case .ping:
            // SEE `autoReplyPing = true` in `init()`.
            break
        case .pong:
            // SEE `ping()` FOR PONG RECEIVE LOGIC.
            break
        @unknown default:
            // Handle unknown opcodes gracefully - just ignore them
            break
        }
    }

    /// Send some `Data` over the  active `connection`.
    /// - Parameters:
    ///   - data: Some `Data` to send (this should be formatted as binary or UTF-8 encoded text).
    ///   - context: `ContentContext` representing the message to send, and its metadata.
    private func send(data: Data?, context: NWConnection.ContentContext) {
        connection?.send(content: data,
                         contentContext: context,
                         isComplete: true,
                         completion: .contentProcessed({ [weak self] error in
            guard let self = self else {
                return
            }

            // If a connection closure was sent, inform delegate on completion
            if let socketMetadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata,
               socketMetadata.opcode == .close {
                self.scheduleDisconnectionReporting(closeCode: socketMetadata.closeCode,
                                                    reason: data)
            }

            if let error = error {
                self.reportErrorOrDisconnection(error)
            }
        }))
    }

    // MARK: Connection cleanup

    /// Schedules the reporting of a WebSocket disconnection.
    ///
    /// The disconnection will be actually reported once the underlying `NWConnection` has been fully torn down.
    /// - Parameters:
    ///   - closeCode: A `NWProtocolWebSocket.CloseCode` describing how the connection closed.
    ///   - reason: Optional extra information explaining the disconnection. (Formatted as UTF-8 encoded `Data`).
    private func scheduleDisconnectionReporting(closeCode: NWProtocolWebSocket.CloseCode,
                                                reason: Data?) {
        var workItemToExecute: DispatchWorkItem?

        disconnectionQueue.sync {
            // Cancel any existing `disconnectionWorkItem` that was set first
            disconnectionWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.delegate?.webSocketDidDisconnect(connection: self,
                        closeCode: closeCode,
                        reason: reason)
            }

            disconnectionWorkItem = workItem
            workItemToExecute = workItem
        }

        if let workItem = workItemToExecute {
            connectionQueue.async(execute: workItem)
        }
    }

    /// Tear down the `connection`.
    ///
    /// This method should only be called in response to a `connection` which has entered either
    /// a `cancelled` or `failed` state within the `stateUpdateHandler` closure.
    /// - Parameter error: error description
    private func tearDownConnection(error: NWError?) {
        let connectionToTearDown = connection

        // Mark as intentional first
        connectionToTearDown?.intentionalDisconnection = true

        if let error = error, shouldReportNWError(error) {
            delegate?.webSocketDidReceiveError(connection: self, error: error)
        }
        pingTimer?.invalidate()

        // Clear connection reference
        connection = nil

        // Cleanup on a different queue to avoid deadlock
        connectionQueue.async { [weak connectionToTearDown] in
            // Clear all handlers before cancelling to prevent race conditions
            connectionToTearDown?.stateUpdateHandler = nil
            connectionToTearDown?.betterPathUpdateHandler = nil
            connectionToTearDown?.viabilityUpdateHandler = nil

            // Small delay to let any in-flight callbacks complete
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                guard let connection = connectionToTearDown else { return }

                // Only cancel if not already cancelled
                if connection.state != .cancelled {
                    connection.cancel()
                }
            }
        }

        let workItem = disconnectionWorkItem
        if let workItem = workItem {
            connectionQueue.async(execute: workItem)
        }
    }

    /// Reports the `error` to the `delegate` (if appropriate) and if it represents an unexpected
    /// disconnection event, the disconnection will also be reported.
    /// - Parameter error: The `NWError` to inspect.
    private func reportErrorOrDisconnection(_ error: NWError) {
        if shouldReportNWError(error) {
            delegate?.webSocketDidReceiveError(connection: self, error: error)
        }

        // Only schedule disconnection if we haven't already scheduled one
        if isDisconnectionNWError(error) && disconnectionWorkItem == nil {
            let reasonData = "The websocket disconnected unexpectedly".data(using: .utf8)
            scheduleDisconnectionReporting(closeCode: .protocolCode(.goingAway),
                                           reason: reasonData)
        }
    }

    /// Determine if a Network error should be reported.
    ///
    /// POSIX errors of either `ENOTCONN` ("Socket is not connected") or
    /// `ECANCELED` ("Operation canceled") should not be reported if the disconnection was intentional.
    /// All other errors should be reported.
    /// - Parameter error: The `NWError` to inspect.
    /// - Returns: `true` if the error should be reported.
    private func shouldReportNWError(_ error: NWError) -> Bool {
        if case let .posix(code) = error,
           code == .ENOTCONN || code == .ECANCELED,
           (connection?.intentionalDisconnection ?? false) {
            return false
        } else {
            return true
        }
    }

    /// Determine if a Network error represents an unexpected disconnection event.
    /// - Parameter error: The `NWError` to inspect.
    /// - Returns: `true` if the error represents an unexpected disconnection event.
    private func isDisconnectionNWError(_ error: NWError) -> Bool {
        if case let .posix(code) = error,
           code == .ETIMEDOUT
            || code == .ENOTCONN
            || code == .ECANCELED
            || code == .ENETDOWN
            || code == .ECONNABORTED {
            return true
        } else {
            return false
        }
    }
}
