import Foundation

public final class CalendarMarkStore {
    private let fileURL: URL
    private let fileManager: FileManager
    private let now: () -> Date
    private let idGenerator: () -> UUID

    public init(
        fileURL: URL,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init,
        idGenerator: @escaping () -> UUID = UUID.init
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.now = now
        self.idGenerator = idGenerator
    }

    public func load() throws -> CalendarEventDocument {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return CalendarEventDocument()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            if let current = try? decoder.decode(CalendarEventDocument.self, from: data),
               current.version == 2 {
                return current
            }
            if let legacy = try? decoder.decode(CalendarMarkDocument.self, from: data),
               legacy.version == 1 {
                return try migrate(legacy)
            }
            throw CocoaError(.fileReadCorruptFile)
        } catch {
            try preserveBrokenFile()
            return CalendarEventDocument()
        }
    }

    public func add(_ event: CalendarEvent, for dateKey: String) throws {
        var document = try load()
        document.add(event, for: dateKey)
        try save(document)
    }

    public func remove(eventID: UUID, for dateKey: String) throws {
        var document = try load()
        document.remove(eventID: eventID, for: dateKey)
        try save(document)
    }

    public func save(_ document: CalendarEventDocument) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }

    private func migrate(_ legacy: CalendarMarkDocument) throws -> CalendarEventDocument {
        var document = CalendarEventDocument()
        for dateKey in legacy.marks.keys.sorted() {
            guard let mark = legacy.marks[dateKey] else { continue }
            let title = mark.note.isEmpty ? mark.category.displayName : mark.note
            let event = try CalendarEvent(id: idGenerator(), title: title)
            document.add(event, for: dateKey)
        }
        return document
    }

    private func preserveBrokenFile() throws {
        let timestamp = Int(now().timeIntervalSince1970)
        let backup = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(fileURL.lastPathComponent).broken-\(timestamp)-\(UUID().uuidString)")
        try fileManager.moveItem(at: fileURL, to: backup)
    }
}
