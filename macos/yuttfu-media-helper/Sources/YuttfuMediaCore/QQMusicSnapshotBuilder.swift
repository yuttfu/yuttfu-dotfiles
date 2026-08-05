import Foundation

public struct QQMusicAccessibilityState: Equatable, Sendable {
    public let playbackState: PlaybackState
    public let elapsed: TimeInterval?
    public let permissionState: MediaPermissionState

    public init(
        playbackState: PlaybackState,
        elapsed: TimeInterval?,
        permissionState: MediaPermissionState
    ) {
        self.playbackState = playbackState
        self.elapsed = elapsed
        self.permissionState = permissionState
    }
}

public struct QQMusicSnapshotBuilder {
    public init() {}

    public func build(
        tracks: [MediaTrack],
        currentSongID: String?,
        accessibility: QQMusicAccessibilityState?,
        observedAt: Date
    ) -> MediaSnapshot? {
        guard let currentSongID,
              let track = tracks.first(where: { $0.trackID == currentSongID }) else {
            return nil
        }

        return MediaSnapshot(
            track: track,
            elapsed: accessibility?.elapsed,
            playbackState: accessibility?.playbackState ?? .paused,
            observedAt: observedAt,
            permissionState: accessibility?.permissionState ?? .missing
        )
    }
}
