import AppKit
import YuttfuCalendarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var store = CalendarMarkStore(
        fileURL: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/yuttfu-sketchybar/calendar-marks.json")
    )
    private lazy var panelController = CalendarPanelController(store: store)

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

    private func handle(_ url: URL) {
        guard url.scheme == "yuttfu-calendar", url.host == "toggle" else { return }
        panelController.toggle(anchor: NSEvent.mouseLocation)
    }
}
