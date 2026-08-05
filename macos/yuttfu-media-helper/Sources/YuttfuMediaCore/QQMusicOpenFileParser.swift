import Foundation

public struct QQMusicOpenFileParser {
    public init() {}

    public func currentSongID(from output: String) -> String? {
        let lines = output.split(separator: "\n").map(String.init)
        if let active = lines.first(where: { line in
            line.range(of: #"\s\d+r\s"#, options: .regularExpression) != nil && line.contains("/iMusic/")
        }), let songID = songID(from: active) {
            return songID
        }

        for line in lines.reversed() where line.contains("/iMusic/") {
            if let songID = songID(from: line) {
                return songID
            }
        }
        return nil
    }

    private func songID(from line: String) -> String? {
        guard let range = line.range(of: #"/([0-9]+)-[0-9]+\.[^/\s]+$"#, options: .regularExpression) else {
            return nil
        }
        let component = line[range].dropFirst()
        return component.split(separator: "-").first.map(String.init)
    }
}
