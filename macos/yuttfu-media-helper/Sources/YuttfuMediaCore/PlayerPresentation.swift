import Foundation

public struct PlayerPresentation: Equatable, Sendable {
    public let snapshot: MediaSnapshot

    public init(snapshot: MediaSnapshot) {
        self.snapshot = snapshot
    }

    public var elapsedText: String {
        guard let elapsed = snapshot.elapsed else { return "--:--" }
        return Self.format(elapsed)
    }

    public var durationText: String {
        guard let duration = snapshot.track.duration else { return "--:--" }
        return Self.format(duration)
    }

    public var progressEnabled: Bool {
        snapshot.elapsed != nil && (snapshot.track.duration ?? 0) > 0
    }

    public var progress: Double {
        guard let elapsed = snapshot.elapsed,
              let duration = snapshot.track.duration,
              duration > 0 else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }

    private static func format(_ interval: TimeInterval) -> String {
        let seconds = max(Int(interval.rounded(.down)), 0)
        let minutes = seconds / 60
        return String(format: "%02d:%02d", minutes, seconds % 60)
    }
}
