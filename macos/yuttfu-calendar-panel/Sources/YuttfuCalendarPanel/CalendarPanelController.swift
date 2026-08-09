import AppKit
import YuttfuCalendarCore

@MainActor
private final class CalendarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class CalendarPanelController: NSObject, NSTextFieldDelegate {
    private let panel: CalendarPanel
    private let store: CalendarMarkStore
    private var calendar: Calendar
    private var document = CalendarMarkDocument()
    private var displayedDate: Date
    private var selectedDate: Date

    private let monthLabel = NSTextField(labelWithString: "")
    private let selectedDateLabel = NSTextField(labelWithString: "")
    private let noteField = NSTextField(string: "")
    private let feedbackLabel = NSTextField(labelWithString: "")
    private let categoryControl = NSSegmentedControl(
        labels: CalendarCategory.allCases.map(\.displayName),
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let grid: CalendarGridView
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
            contentRect: NSRect(x: 0, y: 0, width: 276, height: 390),
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

        let divider = NSBox()
        divider.boxType = .separator
        divider.widthAnchor.constraint(equalToConstant: 238).isActive = true
        root.addArrangedSubview(divider)

        selectedDateLabel.textColor = Theme.subtext
        selectedDateLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        selectedDateLabel.alignment = .left
        selectedDateLabel.widthAnchor.constraint(equalToConstant: 238).isActive = true
        root.addArrangedSubview(selectedDateLabel)

        categoryControl.target = self
        categoryControl.action = #selector(categoryChanged)
        categoryControl.selectedSegment = 0
        categoryControl.segmentStyle = .rounded
        categoryControl.widthAnchor.constraint(equalToConstant: 238).isActive = true
        root.addArrangedSubview(categoryControl)

        noteField.placeholderString = "写一句备注"
        noteField.delegate = self
        noteField.textColor = Theme.text
        noteField.font = .systemFont(ofSize: 11)
        noteField.backgroundColor = Theme.surface.withAlphaComponent(0.7)
        noteField.isBezeled = true
        noteField.bezelStyle = .roundedBezel
        noteField.focusRingType = .none
        noteField.widthAnchor.constraint(equalToConstant: 238).isActive = true
        root.addArrangedSubview(noteField)

        let clear = actionButton("清除", color: Theme.subtext, action: #selector(clearMark))
        let save = actionButton("保存标记", color: Theme.lavender, action: #selector(saveMark))
        let actions = NSStackView(views: [clear, save])
        actions.orientation = .horizontal
        actions.alignment = .centerY
        actions.spacing = 12
        root.addArrangedSubview(actions)

        feedbackLabel.textColor = Theme.red
        feedbackLabel.font = .systemFont(ofSize: 10, weight: .medium)
        feedbackLabel.alignment = .center
        feedbackLabel.isHidden = true
        root.addArrangedSubview(feedbackLabel)
    }

    private func wireInteractions() {
        grid.onSelect = { [weak self] date in
            self?.select(date, beginEditing: false)
        }
        grid.onEdit = { [weak self] date in
            self?.select(date, beginEditing: true)
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
            feedbackLabel.isHidden = true
        } catch {
            document = CalendarMarkDocument()
            showError("无法读取本地标记")
        }
        refresh()
    }

    private func refresh() {
        let displayed = calendar.dateComponents([.year, .month], from: displayedDate)
        let selected = calendar.dateComponents([.month, .day, .weekday], from: selectedDate)
        let year = displayed.year ?? 0
        let month = displayed.month ?? 0
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]

        monthLabel.stringValue = "\(year)年 \(month)月"
        selectedDateLabel.stringValue = String(
            format: "%@  %02d月%02d日",
            weekdayNames[max(0, min(6, (selected.weekday ?? 1) - 1))],
            selected.month ?? 0,
            selected.day ?? 0
        )

        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        let mark = document.marks[key]
        if let mark, let index = CalendarCategory.allCases.firstIndex(of: mark.category) {
            categoryControl.selectedSegment = index
            noteField.stringValue = mark.note
        } else {
            categoryControl.selectedSegment = 0
            noteField.stringValue = ""
        }

        grid.update(
            year: year,
            month: month,
            today: Date(),
            selectedDate: selectedDate,
            marks: document.marks
        )
    }

    private func select(_ date: Date, beginEditing: Bool) {
        selectedDate = calendar.startOfDay(for: date)
        refresh()
        if beginEditing {
            panel.makeFirstResponder(noteField)
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

    private func actionButton(_ title: String, color: NSColor, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.contentTintColor = color
        button.font = .systemFont(ofSize: 11, weight: .semibold)
        button.widthAnchor.constraint(equalToConstant: 108).isActive = true
        return button
    }

    private func showError(_ message: String) {
        feedbackLabel.stringValue = message
        feedbackLabel.isHidden = false
    }

    @objc private func previousMonth() {
        displayedDate = calendar.date(byAdding: .month, value: -1, to: displayedDate) ?? displayedDate
        refresh()
    }

    @objc private func nextMonth() {
        displayedDate = calendar.date(byAdding: .month, value: 1, to: displayedDate) ?? displayedDate
        refresh()
    }

    @objc private func returnToToday() {
        selectedDate = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        displayedDate = calendar.date(from: components) ?? selectedDate
        refresh()
    }

    @objc private func categoryChanged() {
        feedbackLabel.isHidden = true
    }

    @objc private func saveMark() {
        let index = max(0, categoryControl.selectedSegment)
        guard CalendarCategory.allCases.indices.contains(index) else { return }
        let mark = CalendarMark(category: CalendarCategory.allCases[index], note: noteField.stringValue)
        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        do {
            try store.set(mark, for: key)
            document.marks[key] = mark
            feedbackLabel.isHidden = true
            refresh()
        } catch {
            showError("无法保存本地标记")
        }
    }

    @objc private func clearMark() {
        let key = CalendarGridView.dateKey(selectedDate, calendar: calendar)
        do {
            try store.set(nil, for: key)
            document.marks.removeValue(forKey: key)
            feedbackLabel.isHidden = true
            refresh()
        } catch {
            showError("无法清除本地标记")
        }
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        if let movement = notification.userInfo?["NSTextMovement"] as? Int,
           movement == NSReturnTextMovement {
            saveMark()
        }
    }
}
