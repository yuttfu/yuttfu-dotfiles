import AppKit
import YuttfuMediaCore

final class QQMusicProvider {
    private let bundleID = "com.tencent.QQMusicMac"
    private let runner = CommandRunner()
    private let accessibility = QQMusicAccessibilityClient()
    private let parser = QQMusicArchiveParser()
    private let openFileParser = QQMusicOpenFileParser()
    private let snapshotBuilder = QQMusicSnapshotBuilder()
    private let artworkCache = ArtworkCache()

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    func snapshot() -> MediaSnapshot? {
        guard isRunning,
              let data = try? Data(contentsOf: archiveURL),
              let tracks = try? parser.parse(data: data),
              let lsof = runner.output("/usr/sbin/lsof", ["-c", "QQMusic"]) else {
            return nil
        }
        guard let snapshot = snapshotBuilder.build(
            tracks: tracks,
            currentSongID: openFileParser.currentSongID(from: lsof),
            accessibility: accessibility.state(),
            observedAt: Date()
        ) else { return nil }
        let localArtwork = artworkCache.localPath(for: snapshot.track)
        return snapshot.replacingTrack(snapshot.track.replacingArtworkPath(localArtwork))
    }

    func perform(_ command: MediaCommand) {
        accessibility.perform(command)
    }

    func seek(to seconds: TimeInterval) {
        accessibility.seek(to: seconds)
    }

    func replay(_ track: MediaTrack) {
        accessibility.replay(track)
    }

    func openAccessibilitySettings() {
        accessibility.openAccessibilitySettings()
    }

    func requestAccessibilityIfNeeded() {
        accessibility.requestAccessIfNeeded()
    }

    private var archiveURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/com.tencent.QQMusicMac/Data/Library/Application Support/QQMusicMac/iTemp/PlayingList.archive")
    }
}
