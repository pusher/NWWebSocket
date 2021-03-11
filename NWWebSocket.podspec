Pod::Spec.new do |s|
    s.name             = 'NWWebSocket'
    s.version          = '0.5.2'
    s.summary          = 'A WebSocket client written in Swift, using the Network framework from Apple'
    s.homepage         = 'https://github.com/pusher/NWWebSocket'
    s.license          = 'MIT'
    s.author           = { "Pusher Limited" => "support@pusher.com" }
    s.source           = { git: "https://github.com/pusher/NWWebSocket.git", tag: s.version.to_s }
    s.social_media_url = 'https://twitter.com/pusher'

    s.swift_version = '5.1'
    s.requires_arc  = true
    s.source_files  = ['Sources/**/*.swift']

    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.tvos.deployment_target = '13.0'
    s.watchos.deployment_target = '6.0'
end
