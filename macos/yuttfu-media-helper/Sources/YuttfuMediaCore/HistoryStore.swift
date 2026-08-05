import Foundation

public struct HistoryStore: Sendable {
    public let fileURL: URL
    public let maximumEntries: Int

    public init(fileURL: URL, maximumEntries: Int = 6) {
        self.fileURL = fileURL
        self.maximumEntries = maximumEntries
    }

    public func load() throws -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([HistoryEntry].self, from: data)
        } catch {
            try backupCorruptFile()
            return []
        }
    }

    public func record(_ track: MediaTrack, observedAt: Date = Date()) throws {
        var entries = try load()
        entries.removeAll { $0.track.historyKey == track.historyKey }
        entries.insert(HistoryEntry(track: track, observedAt: observedAt), at: 0)
        if entries.count > maximumEntries {
            entries.removeLast(entries.count - maximumEntries)
        }
        try save(entries)
    }

    private func save(_ entries: [HistoryEntry]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    private func backupCorruptFile() throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = URL(fileURLWithPath: fileURL.path + ".corrupt-\(timestamp)")
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}
