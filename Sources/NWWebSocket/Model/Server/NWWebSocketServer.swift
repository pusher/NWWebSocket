import Foundation
import Network

internal class NWSwiftWebSocketServer {

    // MARK: - Private properties

    private let port: NWEndpoint.Port
    private let listener: NWListener
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
        listener = try! NWListener(using: parameters, on: self.port)
    }

    // MARK: - Public methods

    func start() throws {
        print("Server starting...")
        listener.stateUpdateHandler = self.stateDidChange(to:)
        listener.newConnectionHandler = self.didAccept(nwConnection:)
        listener.start(queue: .main)
    }

    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            print("Server ready.")
        case .failed(let error):
            print("Server failure, error: \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        default:
            break
        }
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

    private func connectionDidStop(_ connection: NWServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        print("server did close connection \(connection.id)")
    }

    private func stop() {
        self.listener.stateUpdateHandler = nil
        self.listener.newConnectionHandler = nil
        self.listener.cancel()
        for connection in self.connectionsByID.values {
            connection.didStopHandler = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
}
