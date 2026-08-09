import AppKit
import YuttfuCalendarCore

enum Theme {
    static let base = NSColor(calibratedRed: 0.118, green: 0.118, blue: 0.180, alpha: 0.94)
    static let surface = NSColor(calibratedRed: 0.192, green: 0.196, blue: 0.271, alpha: 0.82)
    static let surfaceRaised = NSColor(calibratedRed: 0.271, green: 0.278, blue: 0.353, alpha: 0.72)
    static let text = NSColor(calibratedRed: 0.804, green: 0.839, blue: 0.957, alpha: 1)
    static let subtext = NSColor(calibratedRed: 0.651, green: 0.678, blue: 0.784, alpha: 1)
    static let muted = NSColor(calibratedRed: 0.424, green: 0.439, blue: 0.525, alpha: 1)
    static let lavender = NSColor(calibratedRed: 0.706, green: 0.745, blue: 0.996, alpha: 1)
    static let mauve = NSColor(calibratedRed: 0.796, green: 0.651, blue: 0.969, alpha: 1)
    static let teal = NSColor(calibratedRed: 0.580, green: 0.886, blue: 0.835, alpha: 1)
    static let green = NSColor(calibratedRed: 0.651, green: 0.890, blue: 0.631, alpha: 1)
    static let peach = NSColor(calibratedRed: 0.980, green: 0.702, blue: 0.529, alpha: 1)
    static let red = NSColor(calibratedRed: 0.953, green: 0.545, blue: 0.659, alpha: 1)

    static func color(for category: CalendarCategory) -> NSColor {
        switch category {
        case .acm: lavender
        case .ai: teal
        case .course: peach
        case .personal: mauve
        }
    }
}
