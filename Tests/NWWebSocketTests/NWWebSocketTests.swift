import XCTest
import Network
import Darwin
@testable import NWWebSocket

class NWWebSocketTests: XCTestCase {
    static var socket: NWWebSocket!
    static var server: NWSwiftWebSocketServer!

    static var connectExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var disconnectExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = true
        }
    }
    static var stringMessageExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var dataMessageExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var pongExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var pingsWithIntervalExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var errorExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }

    static var shouldDisconnectImmediately: Bool!
    static var receivedPongTimestamps: [Date]!

    static let expectationTimeout = 5.0
    static let stringMessage = "This is a string message!"
    static let dataMessage = "This is a data message!".data(using: .utf8)!
    static let expectedReceivedPongsCount = 3
    static let repeatedPingInterval = 0.5
    static var validLocalhostServerPort: UInt16 = 3000
    static let invalidLocalhostServerPort: UInt16 = 2000

    /// Find an available port to avoid conflicts
    private static func findAvailablePort() -> UInt16 {
        // Try ports starting from 3000
        for port in 3000...3100 {
            let testSocket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
            defer { close(testSocket) }
            
            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = CFSwapInt16HostToBig(UInt16(port))
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")
            
            let result = withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.bind(testSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            
            if result == 0 {
                return UInt16(port)
            }
        }
        
        // Fallback to random port in range
        return UInt16.random(in: 3000...4000)
    }

    override func setUp() {
        super.setUp()

        // Find an available port to avoid conflicts
        Self.validLocalhostServerPort = Self.findAvailablePort()
        
        Self.server = NWSwiftWebSocketServer(port: Self.validLocalhostServerPort)
        try! Self.server.start()
        let serverURL = URL(string: "ws://localhost:\(Self.validLocalhostServerPort)")!
        Self.socket = NWWebSocket(url: serverURL)
        Self.socket.delegate = self
        Self.receivedPongTimestamps = []
    }

    override func tearDown() {
        super.tearDown()
        
        // Clean up socket
        if Self.socket != nil {
            Self.socket.disconnect()
            Self.socket = nil
        }
        
        // Clean up server with proper async handling
        if Self.server != nil {
            let expectation = XCTestExpectation(description: "Server cleanup")
            Self.server.stop {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
            Self.server = nil
        }
        
        // Reset all expectations
        Self.connectExpectation = nil
        Self.disconnectExpectation = nil
        Self.stringMessageExpectation = nil
        Self.dataMessageExpectation = nil
        Self.pongExpectation = nil
        Self.pingsWithIntervalExpectation = nil
        Self.errorExpectation = nil
        Self.receivedPongTimestamps = []
    }

    // MARK: - Test methods

    func testConnect() {
        Self.connectExpectation = XCTestExpectation(description: "connectExpectation")
        Self.socket.connect()
        wait(for: [Self.connectExpectation!], timeout: Self.expectationTimeout)
    }

    func testDisconnect() {
        Self.disconnectExpectation = XCTestExpectation(description: "disconnectExpectation")
        Self.socket.connect()
        wait(for: [Self.disconnectExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveStringMessage() {
        Self.stringMessageExpectation = XCTestExpectation(description: "stringMessageExpectation")
        Self.socket.connect()
        Self.socket.send(string: Self.stringMessage)
        wait(for: [Self.stringMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveDataMessage() {
        Self.dataMessageExpectation = XCTestExpectation(description: "dataMessageExpectation")
        Self.socket.connect()
        Self.socket.send(data: Self.dataMessage)
        wait(for: [Self.dataMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceivePong() {
        Self.pongExpectation = XCTestExpectation(description: "pongExpectation")
        Self.socket.connect()
        Self.socket.ping()
        wait(for: [Self.pongExpectation!], timeout: Self.expectationTimeout)
    }

    func testPingsWithInterval() {
        Self.pingsWithIntervalExpectation = XCTestExpectation(description: "pingsWithIntervalExpectation")
        Self.socket.connect()
        Self.socket.ping(interval: Self.repeatedPingInterval)
        wait(for: [Self.pingsWithIntervalExpectation!], timeout: Self.expectationTimeout)
    }

    func testReceiveError() {
        // Redefine socket with invalid path
        Self.socket = NWWebSocket(request: URLRequest(url: URL(string: "ws://localhost:\(Self.invalidLocalhostServerPort)")!))
        Self.socket.delegate = self

        Self.errorExpectation = XCTestExpectation(description: "errorExpectation")
        Self.socket.connect()
        wait(for: [Self.errorExpectation!], timeout: Self.expectationTimeout)
    }

}

// MARK: - WebSocketConnectionDelegate conformance

extension NWWebSocketTests: WebSocketConnectionDelegate {

    func webSocketDidConnect(connection: WebSocketConnection) {
        Self.connectExpectation?.fulfill()

        if Self.shouldDisconnectImmediately {
            Self.socket.disconnect()
        }
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        Self.disconnectExpectation?.fulfill()
    }

    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        if isViable == false {
            XCTFail("WebSocket should not become unviable during testing.")
        }
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        XCTFail("WebSocket should not attempt to migrate to a better path during testing.")
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        Self.errorExpectation?.fulfill()
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        Self.pongExpectation?.fulfill()

        guard Self.pingsWithIntervalExpectation != nil else {
            return
        }

        if Self.receivedPongTimestamps.count == Self.expectedReceivedPongsCount {
            Self.pingsWithIntervalExpectation?.fulfill()
        }
        Self.receivedPongTimestamps.append(Date())
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        XCTAssertEqual(string, Self.stringMessage)
        Self.stringMessageExpectation.fulfill()
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        XCTAssertEqual(data, Self.dataMessage)
        Self.dataMessageExpectation.fulfill()
    }
}

