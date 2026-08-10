import Foundation
import Network
@testable import NWWebSocket
import XCTest

final class ReceiveCompletionTests: XCTestCase {
    func testCompleteMessageIsDelivered() {
        XCTAssertTrue(
            NWWebSocket.shouldDeliverReceivedMessage(
                data: Data("{}".utf8),
                context: textContext,
                isComplete: true
            )
        )
    }

    func testIncompleteMessageIsNotDelivered() {
        XCTAssertFalse(
            NWWebSocket.shouldDeliverReceivedMessage(
                data: Data("{\"partial\":".utf8),
                context: textContext,
                isComplete: false
            )
        )
    }

    func testEmptyMessageIsNotDelivered() {
        XCTAssertFalse(
            NWWebSocket.shouldDeliverReceivedMessage(
                data: Data(),
                context: textContext,
                isComplete: true
            )
        )
    }

    func testMessageWithoutContextIsNotDelivered() {
        XCTAssertFalse(
            NWWebSocket.shouldDeliverReceivedMessage(
                data: Data("{}".utf8),
                context: nil,
                isComplete: true
            )
        )
    }

    private var textContext: NWConnection.ContentContext {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        return NWConnection.ContentContext(
            identifier: "test-text-message",
            metadata: [metadata]
        )
    }
}
