import AppKit
import YuttfuMediaCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = MediaCoordinator()
    private let parser = MediaCommandParser()

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if let command = parser.parse(url) {
                coordinator.handle(command)
            }
        }
    }
}
