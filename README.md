# NWWebSocket

![Build Status](https://github.com/pusher/NWWebSocket/workflows/CI/badge.svg)
[![Latest Release](https://img.shields.io/github/v/release/pusher/NWWebSocket)](https://github.com/pusher/NWWebSocket/releases)
[![API Docs](https://img.shields.io/badge/Docs-here!-lightgrey)](https://pusher.github.io/NWWebSocket/)
[![Supported Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpusher%2FNWWebSocket%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pusher/NWWebSocket)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpusher%2FNWWebSocket%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pusher/NWWebSocket)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/NWWebSocket.svg)](https://cocoapods.org/pods/NWWebSocket)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Pusher-blue.svg?style=flat)](http://twitter.com/Pusher)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/pusher/NWWebSocket/master/LICENSE.md)

A WebSocket client written in Swift, using the Network framework from Apple.

- [Supported platforms](#supported-platforms)
- [Installation](#installation)
- [Usage](#usage)
- [Documentation](#documentation)
- [Reporting bugs and requesting features](#reporting-bugs-and-requesting-features)
- [Credits](#credits)
- [License](#license)

## Supported platforms
- Swift 5.1 and above
- Xcode 11.0 and above

### Deployment targets
- iOS 13.0 and above
- macOS 10.15 and above
- tvOS 13.0 and above

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate NWWebSocket into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '14.0'
use_frameworks!

pod 'NWWebSocket', '~> 0.5.7'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update NWWebSocket
$ pod install
```

Also you'll need to make sure that you've not got the version of NWWebSocket locked to an old version in your `Podfile.lock` file.

### Swift Package Manager

To integrate the library into your project using [Swift Package Manager](https://swift.org/package-manager/), you can add the library as a dependency in Xcode – see the [docs](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). The package repository URL is:

```bash
https://github.com/pusher/NWWebSocket.git
```

Alternatively, you can add the library as a dependency in your `Package.swift` file. For example:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "YourPackage",
    products: [
        .library(
            name: "YourPackage",
            targets: ["YourPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pusher/NWWebSocket.git",
                 .upToNextMajor(from: "0.5.7")),
    ],
    targets: [
        .target(
            name: "YourPackage",
            dependencies: ["NWWebSocket"]),
    ]
)
```

You will then need to include both `import Network` and `import NWWebSocket` statements in any source files where you wish to use the library.

## Usage

This section describes how to configure and use NWWebSocket to manage a WebSocket connection.

### Connection and disconnection

Connection and disconnection is straightforward. Connecting to a WebSocket is manual by default, setting `connectAutomatically` to `true` makes connection automatic.

#### Manual connection

```swift
let socketURL = URL(string: "wss://somewebsockethost.com")
let socket = NWWebSocket(url: socketURL)
socket.delegate = self
socket.connect()

// Use the WebSocket…

socket.disconnect()
```

#### Automatic connection

```swift
let socketURL = URL(string: "wss://somewebsockethost.com")
let socket = NWWebSocket(url: socketURL, connectAutomatically: true)
socket.delegate = self

// Use the WebSocket…

socket.disconnect()
```

**NOTES:**

- In the above code examples, `self` must conform to `WebSocketConnectionDelegate` (see [Receiving messages and connection updates](#receiving-messages-and-connection-updates))

### Sending data

UTF-8 encoded strings or binary data can be sent over the WebSocket connection.

```swift
// Sending a `String`
let message = "Hello, world!"
socket.send(string: message)

// Sending some binary data
let data: [UInt8] = [123, 234]
let messageData = Data(data)
socket.send(data: messageData)
```

### Receiving messages and connection updates

String or data messages (as well as connection state updates) can be received by making a type you define conform to `WebSocketConnectionDelegate`. You can then respond to received messages or connection events accordingly.

```swift
extension MyWebSocketConnectionManager: WebSocketConnectionDelegate {

    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
    }

    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        // Respond to a WebSocket connection receiving a `String` message
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
    }
}
```

### Ping and pong

Triggering a Ping on an active WebSocket connection is a best practice method of telling the connected peer that the connection should be maintained. Pings can be triggered on-demand or periodically.

```swift

// Trigger a Ping on demand
socket.ping()

// Trigger a Ping periodically
// (This is useful when messages are infrequently sent across the connection to prevent a connection closure)
socket.ping(interval: 30.0)
```

## Documentation

Full documentation of the library can be found in the [API docs](https://pusher.github.io/NWWebSocket/).

## Reporting bugs and requesting features
- If you have found a bug or have a feature request, please open an issue
- If you want to contribute, please submit a pull request (preferably with some tests 🙂 )

## Credits

NWWebSocket is owned and maintained by [Pusher](https://pusher.com). It was originally created by [Daniel Browne](https://github.com/danielrbrowne).

It uses code from the following repositories:

- [perpetual-learning](https://github.com/MichaelNeas/perpetual-learning/tree/master/ios-sockets)

## License

NWWebSocket is released under the MIT license. See [LICENSE](https://github.com/pusher/NWWebSocket/blob/master/LICENSE.md) for details.
