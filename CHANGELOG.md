# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/pusher/NWWebSocket/compare/0.5.9...HEAD)

## [0.5.9](https://github.com/pusher/NWWebSocket/compare/0.5.8...0.5.9) - 2025-12-05

### Fixed

- Add tvos support back to the podspec [#61]

## [0.5.8](https://github.com/pusher/NWWebSocket/compare/0.5.7...0.5.8) - 2025-12-05

### Fixed

- Websocket reconnection stuck after network disruption [#59]

## [0.5.7](https://github.com/pusher/NWWebSocket/compare/0.5.6...0.5.7) - 2025-06-19

### Fixed

- Handle connecting after connection is started [#58]

## [0.5.6](https://github.com/pusher/NWWebSocket/compare/0.5.5...0.5.6) - 2025-06-18

### Fixed

- Multiple fixes to prevent potential race conditions [#56]
    + Keeping references alive during cleanup
    + Proper ordering and synchronization
    + Defensive programming
    + Delayed cleanup

## [0.5.5](https://github.com/pusher/NWWebSocket/compare/0.5.4...0.5.5) - 2025-06-17

### Fixed

- Multiple fixes to prevent potential crash [#54]
    + Handle empty request url.
    + Clear all handlers before disconnecting/cancelling connections.
    + Invalidate existing ping timers before scheduling a new one.
    + Handle unknown connection states gracefully.
    + Call completionHandler when migrating connections.
    + Fix failing tests.

## [0.5.4](https://github.com/pusher/NWWebSocket/compare/0.5.3...0.5.4) - 2023-12-15

### Fixed

- Fix reconnection loop [#44]

## [0.5.3](https://github.com/pusher/NWWebSocket/compare/0.5.2...0.5.3) - 2023-04-04

### Fixed

- Prevent memory leak when disconnecting and reconnecting.

## [0.5.2](https://github.com/pusher/NWWebSocket/compare/0.5.1...0.5.2) - 2021-03-11

### Fixed

- Resolved an issue preventing App Store submission when integrating NWWebSocket using certain dependency managers.

## [0.5.1](https://github.com/pusher/NWWebSocket/compare/0.5.0...0.5.1) - 2020-12-15

### Fixed

- Resolved a race condition that could prevent a manual reconnection attempt in certain circumstances.

## [0.5.0](https://github.com/pusher/NWWebSocket/compare/0.4.0...0.5.0) - 2020-11-20

### Added

- Connection state reporting and automatic migration when a better network path becomes available.

### Changed

- Improved Apple Quick Help documentation comments coverage.
- Error-reporting improvements (passes the `NWError` directly via the delegate callback).

## [0.4.0](https://github.com/pusher/NWWebSocket/compare/0.3.0...0.4.0) - 2020-10-27

### Added

- watchOS support (6.0 and above).
- Additions to the README to help new users of `NWWebSocket` library.

## [0.3.0](https://github.com/pusher/NWWebSocket/compare/0.2.1...0.3.0) - 2020-10-16

### Added

- [Cocoapods](https://cocoapods.org/) support.

## [0.2.1](https://github.com/pusher/NWWebSocket/compare/0.2.0...0.2.1) - 2020-10-16

### Added

- This CHANGELOG file.

### Changed

- `NWWebSocket` class (and some methods) are now defined as `open` (previously they were `public`).

## [0.2.0](https://github.com/pusher/NWWebSocket/compare/0.1.0...0.2.0) - 2020-10-15

### Added

- [Carthage](https://github.com/Carthage/Carthage) support.

## [0.1.0](https://github.com/pusher/NWWebSocket/compare/dcab0c4dc704ffc3510adc3a2aa8853be49aa9f6...0.1.0) - 2020-10-15

### Added

- Initial version of `NWWebSocket`.
