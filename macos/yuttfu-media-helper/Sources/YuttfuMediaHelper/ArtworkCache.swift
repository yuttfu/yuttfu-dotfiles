import Foundation
import YuttfuMediaCore

final class ArtworkCache {
    private let runner = CommandRunner()
    private let directory: URL
    private var attempted = Set<String>()

    init() {
        directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/yuttfu-sketchybar/artwork", isDirectory: true)
    }

    func localPath(for track: MediaTrack) -> String? {
        if let path = track.artworkPath, FileManager.default.fileExists(atPath: path) {
            return path
        }
        guard let remote = track.artworkURL,
              let remoteURL = URL(string: remote),
              remoteURL.scheme == "https" else { return nil }

        let fileName = safeFileName(track.trackMID ?? track.trackID ?? remoteURL.lastPathComponent)
        let target = directory.appendingPathComponent("\(fileName).jpg")
        if FileManager.default.fileExists(atPath: target.path) {
            return target.path
        }
        guard attempted.insert(remote).inserted else { return nil }

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = target.appendingPathExtension("download")
        let downloaded = runner.run("/usr/bin/curl", [
            "--silent", "--show-error", "--fail", "--location",
            "--max-time", "3", "--output", temporary.path, remote,
        ])
        if downloaded {
            try? FileManager.default.moveItem(at: temporary, to: target)
        } else {
            try? FileManager.default.removeItem(at: temporary)
        }
        return FileManager.default.fileExists(atPath: target.path) ? target.path : nil
    }

    private func safeFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "_" }
        return String(scalars).prefix(80).description
    }
}
