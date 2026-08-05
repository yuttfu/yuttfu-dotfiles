import Foundation

public enum MediaCommand: Equatable, Sendable {
    case togglePanel
    case playPause
    case previous
    case next
}

public struct MediaCommandParser {
    public init() {}

    public func parse(_ url: URL) -> MediaCommand? {
        guard url.scheme == "yuttfu-media" else { return nil }
        switch url.host {
        case "toggle-panel": return .togglePanel
        case "play-pause": return .playPause
        case "previous": return .previous
        case "next": return .next
        default: return nil
        }
    }
}
