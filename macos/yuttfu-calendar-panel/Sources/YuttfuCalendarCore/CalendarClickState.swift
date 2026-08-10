public enum CalendarClickAction: Equatable, Sendable {
    case scheduleView
    case cancelScheduledView
    case showView
    case showAdd
}

public struct CalendarClickState: Equatable, Sendable {
    private var hasScheduledView = false

    public init() {}

    public mutating func receive(clickCount: Int) -> [CalendarClickAction] {
        if clickCount >= 2 {
            let shouldCancelView = hasScheduledView
            hasScheduledView = false
            return shouldCancelView
                ? [.cancelScheduledView, .showAdd]
                : [.showAdd]
        }

        guard clickCount == 1 else { return [] }
        hasScheduledView = true
        return [.scheduleView]
    }

    public mutating func fireScheduledView() -> CalendarClickAction? {
        guard hasScheduledView else { return nil }
        hasScheduledView = false
        return .showView
    }
}
