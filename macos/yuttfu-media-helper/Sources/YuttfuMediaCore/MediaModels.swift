import Foundation

public enum MediaSource: String, Codable, Equatable, Sendable {
    case qqMusic = "qqmusic"
    case netease
}

public enum PlaybackState: String, Codable, Equatable, Sendable {
    case playing
    case paused
    case stopped
    case unavailable
}

public enum MediaPermissionState: String, Codable, Equatable, Sendable {
    case granted
    case missing
    case notRequired
}

public struct MediaTrack: Codable, Equatable, Sendable {
    public let source: MediaSource
    public let sourceBundleID: String
    public let trackID: String?
    public let trackMID: String?
    public let title: String
    public let artist: String
    public let album: String?
    public let duration: TimeInterval?
    public let artworkPath: String?
    public let artworkURL: String?

    public init(
        source: MediaSource,
        sourceBundleID: String,
        trackID: String?,
        trackMID: String?,
        title: String,
        artist: String,
        album: String?,
        duration: TimeInterval?,
        artworkPath: String?,
        artworkURL: String? = nil
    ) {
        self.source = source
        self.sourceBundleID = sourceBundleID
        self.trackID = trackID
        self.trackMID = trackMID
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkPath = artworkPath
        self.artworkURL = artworkURL
    }

    var historyKey: String {
        if let trackMID, !trackMID.isEmpty {
            return "\(source.rawValue):mid:\(trackMID)"
        }
        if let trackID, !trackID.isEmpty {
            return "\(source.rawValue):id:\(trackID)"
        }
        return "\(source.rawValue):text:\(normalized(title)):\(normalized(artist))"
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public func replacingArtworkPath(_ path: String?) -> MediaTrack {
        MediaTrack(
            source: source,
            sourceBundleID: sourceBundleID,
            trackID: trackID,
            trackMID: trackMID,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkPath: path,
            artworkURL: artworkURL
        )
    }
}

public struct HistoryEntry: Codable, Equatable, Sendable {
    public let track: MediaTrack
    public let observedAt: Date

    public init(track: MediaTrack, observedAt: Date) {
        self.track = track
        self.observedAt = observedAt
    }
}

public struct MediaSnapshot: Codable, Equatable, Sendable {
    public let track: MediaTrack
    public let elapsed: TimeInterval?
    public let playbackState: PlaybackState
    public let observedAt: Date
    public let permissionState: MediaPermissionState

    public init(
        track: MediaTrack,
        elapsed: TimeInterval?,
        playbackState: PlaybackState,
        observedAt: Date,
        permissionState: MediaPermissionState
    ) {
        self.track = track
        self.elapsed = elapsed
        self.playbackState = playbackState
        self.observedAt = observedAt
        self.permissionState = permissionState
    }

    public func replacingTrack(_ replacement: MediaTrack) -> MediaSnapshot {
        MediaSnapshot(
            track: replacement,
            elapsed: elapsed,
            playbackState: playbackState,
            observedAt: observedAt,
            permissionState: permissionState
        )
    }
}
