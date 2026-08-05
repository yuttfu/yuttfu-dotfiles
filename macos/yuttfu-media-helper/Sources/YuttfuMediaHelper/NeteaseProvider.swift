import AppKit
import YuttfuMediaCore

final class NeteaseProvider {
    private let runner = CommandRunner()

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.netease.163music").isEmpty
    }

    func snapshot() -> MediaSnapshot? {
        guard isRunning,
              let output = runner.output(
                "/opt/homebrew/bin/nowplaying-cli",
                ["get", "title", "artist", "album", "duration", "elapsedTime", "playbackRate"]
              ) else { return nil }
        let values = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard values.count >= 6, !values[0].isEmpty, values[0] != "(null)" else { return nil }
        let duration = TimeInterval(values[safe: 3] ?? "")
        let elapsed = TimeInterval(values[safe: 4] ?? "")
        let rate = Double(values[safe: 5] ?? "") ?? 0
        let track = MediaTrack(
            source: .netease,
            sourceBundleID: "com.netease.163music",
            trackID: nil,
            trackMID: nil,
            title: values[0],
            artist: values[safe: 1] ?? "",
            album: (values[safe: 2] ?? "").isEmpty ? nil : values[safe: 2],
            duration: duration,
            artworkPath: nil
        )
        return MediaSnapshot(
            track: track,
            elapsed: elapsed,
            playbackState: rate > 0 ? .playing : .paused,
            observedAt: Date(),
            permissionState: .notRequired
        )
    }

    func perform(_ command: MediaCommand) {
        let argument: String
        switch command {
        case .playPause: argument = "togglePlayPause"
        case .previous: argument = "previous"
        case .next: argument = "next"
        case .togglePanel: return
        }
        _ = runner.run("/opt/homebrew/bin/nowplaying-cli", [argument])
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
