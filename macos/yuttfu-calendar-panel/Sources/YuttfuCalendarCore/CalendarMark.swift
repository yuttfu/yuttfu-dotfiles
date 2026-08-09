import Foundation

public struct CalendarMark: Codable, Equatable, Sendable {
    public let category: CalendarCategory
    public let note: String

    public init(category: CalendarCategory, note: String) {
        self.category = category
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = String(trimmed.prefix(120))
    }
}

public struct CalendarMarkDocument: Codable, Equatable, Sendable {
    public var version: Int
    public var marks: [String: CalendarMark]

    public init(version: Int = 1, marks: [String: CalendarMark] = [:]) {
        self.version = version
        self.marks = marks
    }
}
