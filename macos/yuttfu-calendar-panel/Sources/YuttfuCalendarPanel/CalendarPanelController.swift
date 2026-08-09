import AppKit
import YuttfuCalendarCore

@MainActor
private final class CalendarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class CalendarPanelController: NSObject {
    private let panel: CalendarPanel
    private let store: CalendarMarkStore
    private var calendar: Calendar
    private var document = CalendarEventDocument()
    private var displayedDate: Date
    private var selectedDate: Date

    private let monthLabel = NSTextField(labelWithString: "")
    private let grid: CalendarGridView
    private let eventOverlay = CalendarEventOverlayView()
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(store: CalendarMarkStore) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 1
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month], from: today)
        let firstOfMonth = calendar.date(from: components) ?? today

        self.store = store
        self.calendar = calendar
        displayedDate = firstOfMonth
        selectedDate = today
        grid = CalendarGridView(calendar: calendar)
        panel = CalendarPanel(
            contentRect: NSRect(x: 0, y: 0, width: 276, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        configurePanel()
        installEventMonitors()
        wireInteractions()
    }

    func toggle(anchor: NSPoint) {
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }

        eventOverlay.hide()
        reloadDocument()
        positionPanel(anchor: anchor)
        panel.orderFrontRegardless()
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        let visual = NSVisualEffectView(frame: panel.contentView?.bounds ?? .zero)
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 18
        visual.layer?.borderWidth = 1
        visual.layer?.borderColor = Theme.surfaceRaised.cgColor
        visual.layer?.masksToBounds = true
        panel.contentView = visual

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 9
        root.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: visual.leadingAnchor, constant: 18),
            root.trailingAnchor.constraint(equalTo: visual.trailingAnchor, constant: -18),
            root.topAnchor.constraint(equalTo: visual.topAnchor, constant: 14),
            root.bottomAnchor.constraint(lessThanOrEqualTo: visual.bottomAnchor, constant: -14),
        ])

        let previous = textButton("‹", action: #selector(previousMonth))
        let next = textButton("›", action: #selector(nextMonth))
        let today = textButton("今天", action: #selector(returnToToday))
        today.font = .systemFont(ofSize: 11, weight: .semibold)
        today.contentTintColor = Theme.lavender

        monthLabel.textColor = Theme.text
        monthLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        monthLabel.alignment = .center
        monthLabel.widthAnchor.constraint(equalToConstant: 118).isActive = true

        let header = NSStackView(views: [previous, monthLabel, today, next])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 6
        root.addArrangedSubview(header)

        let weekdayRow = NSStackView(views: ["日", "一", "二", "三", "四", "五", "六"].map { value in
            let label = NSTextField(labelWithString: value)
            label.textColor = Theme.muted
            label.font = .systemFont(ofSize: 10, weight: .medium)
            label.alignment = .center
            return label
        })
        weekdayRow.orientation = .horizontal
        weekdayRow.distribution = .fillEqually
        weekdayRow.widthAnchor.constraint(equalToConstant: 238).isActive = true
        root.addArrangedSubview(weekdayRow)

        grid.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grid.widthAnchor.constraint(equalToConstant: 238),
            grid.heightAnchor.constraint(equalToConstant: 192),
        ])
        root.addArrangedSubview(grid)

        eventOverlay.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(eventOverlay)
        NSLayoutConstraint.activate([
            eventOverlay.leadingAnchor.constraint(equalTo: visual.leadingAnchor, constant: 18),
            eventOverlay.trailingAnchor.constraint(equalTo: visual.trailingAnchor, constant: -18),
            eventOverlay.topAnchor.constraint(equalTo: visual.topAnchor, constant: 14),
            eventOverlay.bottomAnchor.constraint(equalTo: visual.bottomAnchor, constant: -14),
        ])
    }

    private func wireInteractions() {
        grid.onSelect = { [weak self] date in
            self?.select(date)
        }
        grid.onEdit = { [weak self] date in
            self?.select(date)
        }
        eventOverlay.onClose = { [weak self] in
            self?.eventOverlay.hide()
        }
        eventOverlay.onAdd = { [weak self] time, title in
            self?.addEvent(time: time, title: title)
        }
        eventOverlay.onDelete = { [weak self] eventID in
            self?.deleteEvent(eventID)
        }
    }

    private func installEventMonitors() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) {
            [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            if event.type == .keyDown, event.keyCode == 53 {
                self.panel.orderOut(nil)
                return nil
            }
            if event.type != .keyDown, !self.panel.frame.contains(NSEvent.mouseLocation) {
                self.panel.orderOut(nil)
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            guard let self, self.panel.isVisible else { return }
            if !self.panel.frame.contains(NSEvent.mouseLocation) {
                self.panel.orderOut(nil)
            }
        }
    }

    private func reloadDocument() {
        do {
            document = try store.load()
        } catch {
            document = CalendarEventDocument()
        }
        refreshGrid()
    }

    private func refreshGrid() {
        let displayed = calendar.dateComponents([.year, .month], from: displayedDate)
        let year = displayed.year ?? 0
        let month = displayed.month ?? 0
        monthLabel.stringValue = "\(year)年 \(month)月"

        let eventDateKeys = Set(document.events.compactMap { key, events in
            events.isEmpty ? nil : key
        })
        grid.update(
            year: year,
            month: month,
            today: Date(),
            selectedDate: selectedDate,
            eventDateKeys: eventDateKeys
        )
    }

    private func select(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        refreshGrid()
        refreshOverlay()
    }

    private func refreshOverlay() {
        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        eventOverlay.show(
            dateTitle: selectedDateTitle(),
            events: document.events(on: key)
        )
    }

    private func selectedDateTitle() -> String {
        let components = calendar.dateComponents([.month, .day, .weekday], from: selectedDate)
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdayNames[max(0, min(6, (components.weekday ?? 1) - 1))]
        return String(
            format: "%@ · %d月%d日",
            weekday,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func addEvent(time: String?, title: String) {
        let event: CalendarEvent
        do {
            event = try CalendarEvent(time: time, title: title)
        } catch CalendarEvent.ValidationError.emptyTitle {
            eventOverlay.showError("请输入事件标题")
            return
        } catch CalendarEvent.ValidationError.invalidTime {
            eventOverlay.showError("时间格式应为 HH:mm")
            return
        } catch {
            eventOverlay.showError("无法创建本地事件")
            return
        }

        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        var updated = document
        updated.add(event, for: key)
        do {
            try store.save(updated)
            document = updated
            eventOverlay.clearInput()
            refreshGrid()
            refreshOverlay()
        } catch {
            eventOverlay.showError("无法保存本地事件")
        }
    }

    private func deleteEvent(_ eventID: UUID) {
        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        var updated = document
        updated.remove(eventID: eventID, for: key)
        do {
            try store.save(updated)
            document = updated
            refreshGrid()
            refreshOverlay()
        } catch {
            eventOverlay.showError("无法删除本地事件")
        }
    }

    private func positionPanel(anchor: NSPoint) {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let preferredX = anchor.x - panel.frame.width + 86
        let x = min(max(preferredX, visible.minX + 8), visible.maxX - panel.frame.width - 8)
        let y = visible.maxY - panel.frame.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func textButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.contentTintColor = Theme.subtext
        button.font = .systemFont(ofSize: 18, weight: .medium)
        return button
    }

    @objc private func previousMonth() {
        displayedDate = calendar.date(byAdding: .month, value: -1, to: displayedDate) ?? displayedDate
        eventOverlay.hide()
        refreshGrid()
    }

    @objc private func nextMonth() {
        displayedDate = calendar.date(byAdding: .month, value: 1, to: displayedDate) ?? displayedDate
        eventOverlay.hide()
        refreshGrid()
    }

    @objc private func returnToToday() {
        selectedDate = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        displayedDate = calendar.date(from: components) ?? selectedDate
        eventOverlay.hide()
        refreshGrid()
    }
}
