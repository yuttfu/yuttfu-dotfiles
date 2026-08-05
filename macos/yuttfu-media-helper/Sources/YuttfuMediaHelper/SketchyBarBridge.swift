import Foundation
import YuttfuMediaCore

struct SketchyBarBridge {
    private let runner = CommandRunner()

    func publish(_ snapshot: MediaSnapshot?) {
        guard let snapshot else {
            _ = runner.run("/opt/homebrew/bin/sketchybar", [
                "--trigger", "yuttfu_media_changed",
                "STATE=unavailable",
                "TITLE=",
                "ARTIST=",
            ])
            return
        }
        _ = runner.run("/opt/homebrew/bin/sketchybar", [
            "--trigger", "yuttfu_media_changed",
            "STATE=\(snapshot.playbackState.rawValue)",
            "TITLE=\(snapshot.track.title)",
            "ARTIST=\(snapshot.track.artist)",
            "SOURCE=\(snapshot.track.source.rawValue)",
            "ARTWORK=\(snapshot.track.artworkPath ?? "")",
            "PERMISSION=\(snapshot.permissionState.rawValue)",
        ])
    }
}
