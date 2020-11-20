import Network

fileprivate var _intentionalDisconnection: Bool = false

internal extension NWConnection {

    var intentionalDisconnection: Bool {
        get {
            return _intentionalDisconnection
        }
        set {
            _intentionalDisconnection = newValue
        }
    }
}
