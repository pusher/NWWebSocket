import Foundation
import Network

/// Defines a websocket connection.
public protocol WebSocketConnection {
    /// Connect to the websocket.
    func connect()

    /// Send a UTF-8 formatted `String` over the websocket.
    /// - Parameter string: The `String` that will be sent.
    func send(string: String)

    /// Send some `Data` over the websocket.
    /// - Parameter data: The `Data` that will be sent.
    func send(data: Data)

    /// Start listening for messages over the websocket.
    func listen()

    /// Ping the websocket periodically.
    /// - Parameter interval: The `TimeInterval` (in seconds) with which to ping the server.
    func ping(interval: TimeInterval)

    /// Ping the websocket once.
    func ping()

    /// Disconnect from the websocket.
    /// - Parameter closeCode: The code to use when closing the websocket connection.
    func disconnect(closeCode: NWProtocolWebSocket.CloseCode)

    var delegate: WebSocketConnectionDelegate? { get set }
}

/// Defines a delegate for a websocket connection.
public protocol WebSocketConnectionDelegate: AnyObject {
    /// Tells the delegate that the WebSocket did connect successfully.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidConnect(connection: WebSocketConnection)

    /// Tells the delegate that the WebSocket did disconnect.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that disconnected.
    ///   - closeCode: A `NWProtocolWebSocket.CloseCode` describing how the connection closed.
    ///   - reason: Optional extra information explaining the disconnection. (Formatted as UTF-8 encoded `Data`).
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode,
                                reason: Data?)

    /// Tells the delegate that the WebSocket received an error.
    ///
    /// An error received by a WebSocket is not necessarily fatal.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that received an error.
    ///   - error: The `Error` that was received.
    func webSocketDidReceiveError(connection: WebSocketConnection,
                                  error: Error)

    /// Tells the delegate that the WebSocket received a 'pong' from the server.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidReceivePong(connection: WebSocketConnection)

    /// Tells the delegate that the WebSocket received a `String` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - string: The UTF-8 formatted `String` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketConnection,
                                    string: String)

    /// Tells the delegate that the WebSocket received a binary `Data` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - data: The `Data` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketConnection,
                                    data: Data)
}
