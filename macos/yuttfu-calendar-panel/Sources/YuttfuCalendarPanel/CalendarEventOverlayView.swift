import AppKit
import YuttfuCalendarCore

@MainActor
final class CalendarEventOverlayView: NSView {
    var onClose: (() -> Void)?
    var onAdd: ((_ time: String?, _ title: String) -> Void)?
    var onDelete: ((_ eventID: UUID) -> Void)?

    private let dateLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let eventStack = NSStackView()
    private let emptyLabel = NSTextField(labelWithString: "当天暂无事件")
    private let feedbackLabel = NSTextField(labelWithString: "")
    private let timeField = NSTextField(string: "")
    private let titleField = NSTextField(string: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(dateTitle: String, events: [CalendarEvent]) {
        dateLabel.stringValue = dateTitle
        countLabel.stringValue = "\(events.count) 项"
        rebuildEventList(events)
        feedbackLabel.isHidden = true
        isHidden = false
    }

    func hide() {
        isHidden = true
        feedbackLabel.isHidden = true
    }

    func clearInput() {
        timeField.stringValue = ""
        titleField.stringValue = ""
        feedbackLabel.isHidden = true
    }

    func showError(_ message: String) {
        feedbackLabel.stringValue = message
        feedbackLabel.isHidden = false
    }

    private func configure() {
        wantsLayer = true
        layer?.backgroundColor = Theme.base.withAlphaComponent(0.98).cgColor
        layer?.cornerRadius = 14
        layer?.borderWidth = 1
        layer?.borderColor = Theme.surfaceRaised.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.28
        layer?.shadowRadius = 18
        layer?.shadowOffset = NSSize(width: 0, height: -6)

        let close = NSButton(title: "×", target: self, action: #selector(closeOverlay))
        close.isBordered = false
        close.contentTintColor = Theme.subtext
        close.font = .systemFont(ofSize: 15, weight: .medium)

        dateLabel.textColor = Theme.text
        dateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = Theme.muted
        countLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)

        let header = NSStackView(views: [dateLabel, countLabel, close])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8

        eventStack.orientation = .vertical
        eventStack.alignment = .leading
        eventStack.spacing = 5
        eventStack.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.documentView = eventStack
        scroll.heightAnchor.constraint(equalToConstant: 126).isActive = true
        NSLayoutConstraint.activate([
            eventStack.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            eventStack.trailingAnchor.constraint(equalTo: scroll.contentView.trailingAnchor),
            eventStack.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            eventStack.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])

        timeField.placeholderString = "时间"
        timeField.toolTip = "可选，格式 HH:mm"
        timeField.alignment = .center
        timeField.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        timeField.textColor = Theme.text
        timeField.backgroundColor = Theme.surface.withAlphaComponent(0.78)
        timeField.isBezeled = true
        timeField.bezelStyle = .roundedBezel
        timeField.focusRingType = .none
        timeField.widthAnchor.constraint(equalToConstant: 54).isActive = true

        titleField.placeholderString = "事件标题"
        titleField.font = .systemFont(ofSize: 10.5, weight: .medium)
        titleField.textColor = Theme.text
        titleField.backgroundColor = Theme.surface.withAlphaComponent(0.78)
        titleField.isBezeled = true
        titleField.bezelStyle = .roundedBezel
        titleField.focusRingType = .none
        titleField.target = self
        titleField.action = #selector(addEvent)

        let add = NSButton(title: "+", target: self, action: #selector(addEvent))
        add.bezelStyle = .rounded
        add.contentTintColor = Theme.lavender
        add.font = .systemFont(ofSize: 14, weight: .semibold)
        add.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let composer = NSStackView(views: [timeField, titleField, add])
        composer.orientation = .horizontal
        composer.alignment = .centerY
        composer.spacing = 6

        feedbackLabel.textColor = Theme.red
        feedbackLabel.font = .systemFont(ofSize: 9.5, weight: .medium)
        feedbackLabel.alignment = .left
        feedbackLabel.isHidden = true

        let root = NSStackView(views: [header, scroll, composer, feedbackLabel])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            root.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            root.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            header.widthAnchor.constraint(equalTo: root.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: root.widthAnchor),
            composer.widthAnchor.constraint(equalTo: root.widthAnchor),
            feedbackLabel.widthAnchor.constraint(equalTo: root.widthAnchor),
        ])
    }

    private func rebuildEventList(_ events: [CalendarEvent]) {
        for view in eventStack.arrangedSubviews {
            eventStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if events.isEmpty {
            emptyLabel.textColor = Theme.muted
            emptyLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
            emptyLabel.alignment = .center
            emptyLabel.widthAnchor.constraint(equalToConstant: 208).isActive = true
            eventStack.addArrangedSubview(emptyLabel)
            return
        }

        for event in events {
            eventStack.addArrangedSubview(eventRow(event))
        }
    }

    private func eventRow(_ event: CalendarEvent) -> NSView {
        let time = NSTextField(labelWithString: event.time ?? "全天")
        time.textColor = event.time == nil ? Theme.muted : Theme.lavender
        time.font = .monospacedDigitSystemFont(ofSize: 9.5, weight: .medium)
        time.alignment = .left
        time.widthAnchor.constraint(equalToConstant: 38).isActive = true

        let title = NSTextField(labelWithString: event.title)
        title.textColor = Theme.text
        title.font = .systemFont(ofSize: 10.5, weight: .medium)
        title.lineBreakMode = .byTruncatingTail

        let remove = EventDeleteButton(title: "×", target: self, action: #selector(deleteEvent(_:)))
        remove.eventID = event.id
        remove.isBordered = false
        remove.contentTintColor = Theme.muted
        remove.font = .systemFont(ofSize: 13, weight: .medium)
        remove.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let row = NSStackView(views: [time, title, remove])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        row.wantsLayer = true
        row.layer?.backgroundColor = Theme.surface.withAlphaComponent(0.64).cgColor
        row.layer?.cornerRadius = 8
        row.edgeInsets = NSEdgeInsets(top: 4, left: 7, bottom: 4, right: 5)
        row.widthAnchor.constraint(equalToConstant: 208).isActive = true
        return row
    }

    @objc private func closeOverlay() {
        onClose?()
    }

    @objc private func addEvent() {
        let rawTime = timeField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        onAdd?(rawTime.isEmpty ? nil : rawTime, titleField.stringValue)
    }

    @objc private func deleteEvent(_ sender: EventDeleteButton) {
        guard let eventID = sender.eventID else { return }
        onDelete?(eventID)
    }
}

@MainActor
private final class EventDeleteButton: NSButton {
    var eventID: UUID?
}
