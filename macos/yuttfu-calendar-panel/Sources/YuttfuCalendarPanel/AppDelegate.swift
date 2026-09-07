import AppKit
import YuttfuCalendarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var store = CalendarMarkStore(
        fileURL: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/yuttfu-sketchybar/calendar-marks.json")
    )
    private lazy var panelController = CalendarPanelController(store: store)
    private var didFinishLaunching = false
    private var pendingToggleAnchor: NSPoint?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        didFinishLaunching = true
        if let anchor = pendingToggleAnchor {
            pendingToggleAnchor = nil
            DispatchQueue.main.async { [weak self] in
                self?.togglePanel(anchor: anchor)
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(handle)
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelController.stop()
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc
    private func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        guard let value = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: value) else { return }
        handle(url)
    }

    private func togglePanel(anchor: NSPoint) {
        if !panelController.isVisible && Theme.reload() {
            panelController.stop()
            panelController = CalendarPanelController(store: store)
        }
        panelController.toggle(anchor: anchor)
    }

    private func handle(_ url: URL) {
        guard url.scheme == "yuttfu-calendar", url.host == "toggle" else { return }
        let anchor = NSEvent.mouseLocation
        if didFinishLaunching {
            togglePanel(anchor: anchor)
        } else {
            pendingToggleAnchor = anchor
        }
    }
}
