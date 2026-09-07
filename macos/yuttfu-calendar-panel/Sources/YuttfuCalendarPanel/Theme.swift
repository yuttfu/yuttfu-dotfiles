import AppKit
import YuttfuCalendarCore

@MainActor
enum Theme {
    private static let fallback: [String: String] = [
        "base": "#00002c", "surface0": "#14143d", "surface1": "#2e2e53",
        "text": "#ffffff", "subtext0": "#bfbfca", "overlay0": "#637d8a",
        "lavender": "#00f7ff", "mauve": "#ff2c70", "teal": "#00f7ff",
        "green": "#3effb4", "peach": "#ffb86c", "red": "#ff2c70",
    ]
    private static var palette = readPalette() ?? fallback

    private static func readPalette() -> [String: String]? {
        let config = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config")
        guard let data = try? Data(contentsOf: config.appendingPathComponent("terminal-themes/calendar.json")),
              let document = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              document["managed_by"] as? String == "terminal-theme",
              let colors = document["colors"] as? [String: String],
              fallback.keys.allSatisfy({ key in
                  guard let value = colors[key] else { return false }
                  return value.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil
              }) else { return nil }
        return colors
    }

    // Rebuild a hidden panel on its next opening; keep an open event editor intact.
    static func reload() -> Bool {
        guard let updated = readPalette(), updated != palette else { return false }
        palette = updated
        return true
    }

    private static func color(_ key: String, alpha: CGFloat = 1) -> NSColor {
        let value = UInt32(String((palette[key] ?? fallback[key]!).dropFirst()), radix: 16)!
        return NSColor(calibratedRed: CGFloat((value >> 16) & 255) / 255,
                       green: CGFloat((value >> 8) & 255) / 255,
                       blue: CGFloat(value & 255) / 255, alpha: alpha)
    }
    static var base: NSColor { color("base", alpha: 0.94) }
    static var surface: NSColor { color("surface0", alpha: 0.82) }
    static var surfaceRaised: NSColor { color("surface1", alpha: 0.72) }
    static var text: NSColor { color("text") }
    static var subtext: NSColor { color("subtext0") }
    static var muted: NSColor { color("overlay0") }
    static var lavender: NSColor { color("lavender") }
    static var mauve: NSColor { color("mauve") }
    static var teal: NSColor { color("teal") }
    static var green: NSColor { color("green") }
    static var peach: NSColor { color("peach") }
    static var red: NSColor { color("red") }

    static func color(for category: CalendarCategory) -> NSColor {
        switch category {
        case .acm: lavender
        case .ai: teal
        case .course: peach
        case .personal: mauve
        }
    }
}
