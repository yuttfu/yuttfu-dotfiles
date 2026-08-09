import Foundation

public final class CalendarMarkStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let now: () -> Date

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.now = now
    }

    public func load() throws -> CalendarMarkDocument {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return CalendarMarkDocument()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CalendarMarkDocument.self, from: data)
        } catch {
            try preserveBrokenFile()
            return CalendarMarkDocument()
        }
    }

    public func set(_ mark: CalendarMark?, for dateKey: String) throws {
        var document = try load()
        document.marks[dateKey] = mark
        try save(document)
    }

    public func save(_ document: CalendarMarkDocument) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    private func preserveBrokenFile() throws {
        let timestamp = Int(now().timeIntervalSince1970)
        let backup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(fileURL.lastPathComponent).broken-\(timestamp)-\(UUID().uuidString)")
        try fileManager.moveItem(at: fileURL, to: backup)
    }
}
