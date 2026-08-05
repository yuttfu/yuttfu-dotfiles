import Foundation
import YuttfuMediaCore

@MainActor
final class MediaCoordinator {
    private let qqMusic = QQMusicProvider()
    private let netease = NeteaseProvider()
    private let arbiter = SourceArbiter()
    private let bridge = SketchyBarBridge()
    private let panel = PlayerPanelController()
    private let history: HistoryStore
    private var timer: Timer?
    private var current: MediaSnapshot?

    init() {
        let historyURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/yuttfu-sketchybar/media-history.json")
        history = HistoryStore(fileURL: historyURL)
        panel.commandHandler = { [weak self] command in self?.perform(command) }
        panel.seekHandler = { [weak self] seconds in self?.seek(to: seconds) }
        panel.permissionHandler = { [weak self] in self?.qqMusic.openAccessibilitySettings() }
        panel.historyHandler = { [weak self] entry in self?.replay(entry) }
    }

    func start() {
        qqMusic.requestAccessibilityIfNeeded()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func handle(_ command: MediaCommand) {
        if command == .togglePanel {
            panel.toggle()
            return
        }
        perform(command)
    }

    private func refresh() {
        let selected = arbiter.select(
            qqMusic: qqMusic.snapshot(),
            netease: netease.snapshot()
        )
        if let selected, selected.track.historyKeyForBridge != current?.track.historyKeyForBridge {
            try? history.record(selected.track, observedAt: selected.observedAt)
        }
        current = selected
        bridge.publish(selected)
        panel.update(snapshot: selected, history: (try? history.load()) ?? [])
    }

    private func perform(_ command: MediaCommand) {
        switch current?.track.source {
        case .qqMusic: qqMusic.perform(command)
        case .netease: netease.perform(command)
        case nil: break
        }
        refresh()
    }

    private func seek(to seconds: TimeInterval) {
        guard current?.track.source == .qqMusic else { return }
        qqMusic.seek(to: seconds)
        refresh()
    }

    private func replay(_ entry: HistoryEntry) {
        guard entry.track.source == .qqMusic else { return }
        qqMusic.replay(entry.track)
        refresh()
    }
}

private extension MediaTrack {
    var historyKeyForBridge: String {
        let identity = trackMID ?? trackID ?? "\(title):\(artist)"
        return "\(source.rawValue):\(identity)"
    }
}
