import AppKit
import YuttfuMediaCore

@MainActor
final class PlayerPanelController: NSObject {
    var commandHandler: ((MediaCommand) -> Void)?
    var seekHandler: ((TimeInterval) -> Void)?
    var permissionHandler: (() -> Void)?
    var historyHandler: ((HistoryEntry) -> Void)?

    private let panel: NSPanel
    private let artwork = NSImageView()
    private let sourceLabel = NSTextField(labelWithString: "QQ音乐")
    private let titleLabel = NSTextField(labelWithString: "没有正在播放的歌曲")
    private let artistLabel = NSTextField(labelWithString: "")
    private let elapsedLabel = NSTextField(labelWithString: "--:--")
    private let durationLabel = NSTextField(labelWithString: "--:--")
    private let progress = NSSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let playButton = NSButton(title: "▶︎", target: nil, action: nil)
    private let historyStack = NSStackView()
    private let statusButton = NSButton(title: "", target: nil, action: nil)
    private var snapshot: MediaSnapshot?
    private var history: [HistoryEntry] = []

    override init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 390),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()
        configurePanel()
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionPanel()
            panel.orderFrontRegardless()
        }
    }

    func update(snapshot: MediaSnapshot?, history: [HistoryEntry]) {
        self.snapshot = snapshot
        self.history = history
        guard let snapshot else {
            titleLabel.stringValue = "没有正在播放的歌曲"
            artistLabel.stringValue = ""
            progress.isEnabled = false
            return
        }

        let presentation = PlayerPresentation(snapshot: snapshot)
        titleLabel.stringValue = snapshot.track.title
        artistLabel.stringValue = snapshot.track.artist
        sourceLabel.stringValue = snapshot.track.source == .qqMusic ? "QQ音乐" : "网易云音乐"
        elapsedLabel.stringValue = presentation.elapsedText
        durationLabel.stringValue = presentation.durationText
        progress.doubleValue = presentation.progress
        progress.isEnabled = presentation.progressEnabled
        playButton.title = snapshot.playbackState == .playing ? "Ⅱ" : "▶︎"
        artwork.image = artworkImage(for: snapshot.track)
        statusButton.isHidden = snapshot.permissionState != .missing
        statusButton.title = snapshot.permissionState == .missing ? "需要辅助功能权限" : ""
        rebuildHistory()
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let visual = NSVisualEffectView(frame: panel.contentView?.bounds ?? .zero)
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 18
        visual.layer?.borderWidth = 1
        visual.layer?.borderColor = Theme.surface.cgColor
        panel.contentView = visual

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: visual.leadingAnchor, constant: 18),
            root.trailingAnchor.constraint(equalTo: visual.trailingAnchor, constant: -18),
            root.topAnchor.constraint(equalTo: visual.topAnchor, constant: 16),
            root.bottomAnchor.constraint(lessThanOrEqualTo: visual.bottomAnchor, constant: -14),
        ])

        artwork.imageScaling = .scaleProportionallyUpOrDown
        artwork.wantsLayer = true
        artwork.layer?.cornerRadius = 14
        artwork.layer?.masksToBounds = true
        NSLayoutConstraint.activate([
            artwork.widthAnchor.constraint(equalToConstant: 96),
            artwork.heightAnchor.constraint(equalToConstant: 96),
        ])
        root.addArrangedSubview(artwork)

        sourceLabel.textColor = Theme.green
        sourceLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        artistLabel.textColor = Theme.subtext
        artistLabel.font = .systemFont(ofSize: 12)
        root.addArrangedSubview(sourceLabel)
        root.addArrangedSubview(titleLabel)
        root.addArrangedSubview(artistLabel)

        let progressRow = NSStackView(views: [elapsedLabel, progress, durationLabel])
        progressRow.orientation = .horizontal
        progressRow.spacing = 8
        progressRow.alignment = .centerY
        progressRow.distribution = .fill
        elapsedLabel.textColor = Theme.subtext
        durationLabel.textColor = Theme.subtext
        elapsedLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        durationLabel.font = elapsedLabel.font
        progress.target = self
        progress.action = #selector(progressChanged)
        progress.widthAnchor.constraint(equalToConstant: 174).isActive = true
        root.addArrangedSubview(progressRow)

        let previous = controlButton("◀︎", action: #selector(previousPressed))
        playButton.target = self
        playButton.action = #selector(playPressed)
        styleControl(playButton)
        let next = controlButton("▶︎", action: #selector(nextPressed))
        let controls = NSStackView(views: [previous, playButton, next])
        controls.orientation = .horizontal
        controls.spacing = 20
        root.addArrangedSubview(controls)

        let divider = NSBox()
        divider.boxType = .separator
        divider.widthAnchor.constraint(equalToConstant: 270).isActive = true
        root.addArrangedSubview(divider)

        historyStack.orientation = .vertical
        historyStack.alignment = .leading
        historyStack.spacing = 3
        historyStack.widthAnchor.constraint(equalToConstant: 270).isActive = true
        root.addArrangedSubview(historyStack)

        statusButton.isBordered = false
        statusButton.contentTintColor = Theme.red
        statusButton.target = self
        statusButton.action = #selector(permissionPressed)
        statusButton.isHidden = true
        root.addArrangedSubview(statusButton)
    }

    private func rebuildHistory() {
        historyStack.arrangedSubviews.forEach {
            historyStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, entry) in history.prefix(6).enumerated() {
            let button = NSButton(title: "\(entry.track.title)  ·  \(entry.track.artist)", target: self, action: #selector(historyPressed(_:)))
            button.tag = index
            button.isBordered = false
            button.alignment = .left
            button.font = .systemFont(ofSize: 11)
            button.contentTintColor = entry.track.trackID == snapshot?.track.trackID ? Theme.green : Theme.text
            button.lineBreakMode = .byTruncatingTail
            button.widthAnchor.constraint(equalToConstant: 270).isActive = true
            historyStack.addArrangedSubview(button)
        }
    }

    private func artworkImage(for track: MediaTrack) -> NSImage? {
        if let path = track.artworkPath, let image = NSImage(contentsOfFile: path) {
            return image
        }
        let app = track.source == .qqMusic ? "/Applications/QQMusic.app" : "/Applications/NeteaseMusic.app"
        return NSWorkspace.shared.icon(forFile: app)
    }

    private func positionPanel() {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let x = visible.midX - panel.frame.width / 2
        let y = visible.maxY - panel.frame.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func controlButton(_ title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        styleControl(button)
        return button
    }

    private func styleControl(_ button: NSButton) {
        button.bezelStyle = .circular
        button.contentTintColor = Theme.text
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
    }

    @objc private func previousPressed() { commandHandler?(.previous) }
    @objc private func playPressed() { commandHandler?(.playPause) }
    @objc private func nextPressed() { commandHandler?(.next) }
    @objc private func permissionPressed() { permissionHandler?() }
    @objc private func progressChanged() {
        guard let duration = snapshot?.track.duration else { return }
        seekHandler?(progress.doubleValue * duration)
    }
    @objc private func historyPressed(_ sender: NSButton) {
        guard history.indices.contains(sender.tag) else { return }
        historyHandler?(history[sender.tag])
    }
}
