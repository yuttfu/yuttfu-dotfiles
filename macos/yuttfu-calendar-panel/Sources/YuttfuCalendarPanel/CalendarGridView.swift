import AppKit
import YuttfuCalendarCore

@MainActor
final class CalendarGridView: NSView {
    var onSelect: ((Date) -> Void)?
    var onEdit: ((Date) -> Void)?

    private var calendar: Calendar
    private let dayViews: [DayCellView]

    init(calendar: Calendar) {
        self.calendar = calendar
        dayViews = (0..<42).map { _ in DayCellView() }
        super.init(frame: .zero)

        dayViews.forEach { view in
            view.onSelect = { [weak self] date in self?.onSelect?(date) }
            view.onEdit = { [weak self] date in self?.onEdit?(date) }
            addSubview(view)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 238, height: 192)
    }

    override func layout() {
        super.layout()
        let cellWidth = bounds.width / 7
        let cellHeight = bounds.height / 6
        for (index, view) in dayViews.enumerated() {
            let row = index / 7
            let column = index % 7
            view.frame = NSRect(
                x: CGFloat(column) * cellWidth,
                y: bounds.height - CGFloat(row + 1) * cellHeight,
                width: cellWidth,
                height: cellHeight
            )
        }
    }

    func update(
        year: Int,
        month: Int,
        today: Date,
        selectedDate: Date,
        eventDateKeys: Set<String>
    ) {
        let cells = MonthGrid.make(
            year: year,
            month: month,
            calendar: calendar,
            today: today
        )

        for (view, cell) in zip(dayViews, cells) {
            view.update(
                date: cell.date,
                day: cell.day,
                isInDisplayedMonth: cell.isInDisplayedMonth,
                isToday: cell.isToday,
                isSelected: calendar.isDate(cell.date, inSameDayAs: selectedDate),
                markColor: eventDateKeys.contains(Self.dateKey(cell.date, calendar: calendar)) ? Theme.red : nil
            )
        }
    }

    static func dateKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

@MainActor
private final class DayCellView: NSView {
    var onSelect: ((Date) -> Void)?
    var onEdit: ((Date) -> Void)?

    private var date = Date()
    private var day = 0
    private var isInDisplayedMonth = false
    private var isToday = false
    private var isSelected = false
    private var markColor: NSColor?
    private var clickState = CalendarClickState()
    private var pendingSingleClick: DispatchWorkItem?

    override var isFlipped: Bool { false }

    func update(
        date: Date,
        day: Int,
        isInDisplayedMonth: Bool,
        isToday: Bool,
        isSelected: Bool,
        markColor: NSColor?
    ) {
        if self.date != date {
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
            clickState = CalendarClickState()
        }
        self.date = date
        self.day = day
        self.isInDisplayedMonth = isInDisplayedMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.markColor = markColor
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        for action in clickState.receive(clickCount: event.clickCount) {
            switch action {
            case .scheduleView:
                scheduleSingleClick(for: date)
            case .cancelScheduledView:
                pendingSingleClick?.cancel()
                pendingSingleClick = nil
            case .showAdd:
                onEdit?(date)
            case .showView:
                break
            }
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        pendingSingleClick?.cancel()
        pendingSingleClick = nil
        clickState = CalendarClickState()
        onEdit?(date)
    }

    private func scheduleSingleClick(for date: Date) {
        pendingSingleClick?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingSingleClick = nil
            if self.clickState.fireScheduledView() == .showView {
                self.onSelect?(date)
            }
        }
        pendingSingleClick = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + NSEvent.doubleClickInterval,
            execute: work
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let circle = bounds.insetBy(dx: 3, dy: 2)

        if isSelected {
            Theme.surfaceRaised.setFill()
            NSBezierPath(ovalIn: circle).fill()
        }
        if isToday {
            Theme.lavender.setStroke()
            let outline = NSBezierPath(ovalIn: circle.insetBy(dx: 0.75, dy: 0.75))
            outline.lineWidth = 1.5
            outline.stroke()
        }

        let color = isInDisplayedMonth ? Theme.text : Theme.muted
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(
                ofSize: 11,
                weight: isToday || isSelected ? .semibold : .regular
            ),
            .foregroundColor: color,
        ]
        let text = String(day) as NSString
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2 + 2),
            withAttributes: attributes
        )

        if let markColor {
            markColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: bounds.midX - 2, y: 3, width: 4, height: 4)).fill()
        }
    }
}
