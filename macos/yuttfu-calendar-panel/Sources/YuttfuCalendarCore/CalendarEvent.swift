import Foundation

public struct CalendarEvent: Codable, Equatable, Sendable {
    public enum ValidationError: Error, Equatable {
        case emptyTitle
        case invalidTime
    }

    public let id: UUID
    public let time: String?
    public let title: String

    public init(id: UUID = UUID(), time: String? = nil, title: String) throws {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw ValidationError.emptyTitle
        }

        let normalizedTime = time?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedTime, !normalizedTime.isEmpty {
            guard Self.isValidTime(normalizedTime) else {
                throw ValidationError.invalidTime
            }
            self.time = normalizedTime
        } else {
            self.time = nil
        }

        self.id = id
        self.title = String(normalizedTitle.prefix(120))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case time
        case title
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let time = try container.decodeIfPresent(String.self, forKey: .time)
        let title = try container.decode(String.self, forKey: .title)

        do {
            try self.init(id: id, time: time, title: title)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .title,
                in: container,
                debugDescription: "Calendar event contains an invalid title or time."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encode(title, forKey: .title)
    }

    private static func isValidTime(_ value: String) -> Bool {
        let characters = Array(value)
        guard characters.count == 5,
              characters[2] == ":",
              let hour = Int(String(characters[0...1])),
              let minute = Int(String(characters[3...4])) else {
            return false
        }
        return (0...23).contains(hour) && (0...59).contains(minute)
    }
}

public struct CalendarEventDocument: Codable, Equatable, Sendable {
    public var version: Int
    public var events: [String: [CalendarEvent]]

    public init(version: Int = 2, events: [String: [CalendarEvent]] = [:]) {
        self.version = version
        self.events = events
    }

    public func events(on dateKey: String) -> [CalendarEvent] {
        let indexed = (events[dateKey] ?? []).enumerated()
        return indexed.sorted { left, right in
            switch (left.element.time, right.element.time) {
            case let (leftTime?, rightTime?):
                if leftTime == rightTime {
                    return left.offset < right.offset
                }
                return leftTime < rightTime
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return left.offset < right.offset
            }
        }.map(\.element)
    }

    public func hasEvents(on dateKey: String) -> Bool {
        !(events[dateKey] ?? []).isEmpty
    }

    public mutating func add(_ event: CalendarEvent, for dateKey: String) {
        events[dateKey, default: []].append(event)
    }

    public mutating func remove(eventID: UUID, for dateKey: String) {
        guard var dayEvents = events[dateKey] else { return }
        dayEvents.removeAll { $0.id == eventID }
        if dayEvents.isEmpty {
            events.removeValue(forKey: dateKey)
        } else {
            events[dateKey] = dayEvents
        }
    }
}
