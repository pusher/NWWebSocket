import Foundation
import Network

internal class NWSwiftWebSocketServer {

    // MARK: - Private properties

    private let port: NWEndpoint.Port
    private var listener: NWListener?
    private let parameters: NWParameters
    private var connectionsByID: [Int: NWServerConnection] = [:]

    // MARK: - Lifecycle

    init(port: UInt16) {
        self.port = NWEndpoint.Port(rawValue: port)!
        parameters = NWParameters(tls: nil)
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
    }

    // MARK: - Public methods

    func start() throws {
        print("Server starting...")
        if listener == nil {
            listener = try! NWListener(using: parameters, on: self.port)
        }
        listener?.stateUpdateHandler = self.stateDidChange(to:)
        listener?.newConnectionHandler = self.didAccept(nwConnection:)
        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    func stop(completion: @escaping () -> Void) {
        guard listener != nil else {
            completion()
            return
        }
        
        // Set up completion handler before stopping
        listener?.stateUpdateHandler = { state in
            switch state {
            case .cancelled:
                completion()
            default:
                break
            }
        }
        
        listener?.cancel()
        listener = nil
    }

    // MARK: - Private methods

    private func didAccept(nwConnection: NWConnection) {
        let connection = NWServerConnection(nwConnection: nwConnection)
        connectionsByID[connection.id] = connection
        
        connection.start()
        
        connection.didStopHandler = { err in
            if let err = err {
                print(err)
            }
            self.connectionDidStop(connection)
        }
        connection.didReceiveStringHandler = { string in
            self.connectionsByID.values.forEach { connection in
                print("sent \(string) to open connection \(connection.id)")
                connection.send(string: string)
            }
        }
        connection.didReceiveDataHandler = { data in
            self.connectionsByID.values.forEach { connection in
                print("sent \(String(data: data, encoding: .utf8) ?? "NOTHING") to open connection \(connection.id)")
                connection.send(data: data)
            }
        }
        
        print("server did open connection \(connection.id)")
    }

    private func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .setup:
            print("Server is setup.")
        case .waiting(let error):
            print("Server is waiting to start, non-fatal error: \(error.debugDescription)")
        case .ready:
            print("Server ready.")
        case .cancelled:
            self.stopSever(error: nil)
        case .failed(let error):
            self.stopSever(error: error)
        @unknown default:
            fatalError()
        }
    }

    private func connectionDidStop(_ connection: NWServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        print("server did close connection \(connection.id)")
    }

    private func stopSever(error: NWError?) {
        self.listener?.cancel()
        self.listener = nil
        for connection in self.connectionsByID.values {
            connection.didStopHandler = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
        if let error = error {
            print("Server failure, error: \(error.debugDescription)")
        } else {
            print("Server stopped normally.")
        }
    }
}
