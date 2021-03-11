# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/pusher/NWWebSocket/compare/0.5.2...HEAD)

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
