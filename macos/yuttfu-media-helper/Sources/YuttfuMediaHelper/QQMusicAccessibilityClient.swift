import ApplicationServices
import AppKit
import YuttfuMediaCore

final class QQMusicAccessibilityClient {
    private let bundleID = "com.tencent.QQMusicMac"

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessIfNeeded() {
        guard !isTrusted else { return }
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func state() -> QQMusicAccessibilityState? {
        guard isTrusted, let root = applicationElement() else { return nil }
        let elements = descendants(of: root)
        let playing = elements.contains { element in
            element.role == kAXButtonRole && element.semanticText.containsAny(["暂停", "pause"])
        }
        let paused = elements.contains { element in
            element.role == kAXButtonRole && element.semanticText.containsAny(["播放", "play"])
        }
        let elapsed = elements
            .first(where: { $0.role == kAXSliderRole })?
            .numberValue

        return QQMusicAccessibilityState(
            playbackState: playing ? .playing : (paused ? .paused : .paused),
            elapsed: elapsed,
            permissionState: .granted
        )
    }

    func perform(_ command: MediaCommand) {
        guard let root = applicationElement() else { return }
        let terms: [String]
        switch command {
        case .playPause: terms = ["播放", "暂停", "play", "pause"]
        case .previous: terms = ["上一首", "previous", "back"]
        case .next: terms = ["下一首", "next", "forward"]
        case .togglePanel: return
        }
        guard let button = descendants(of: root).first(where: {
            $0.role == kAXButtonRole && $0.semanticText.containsAny(terms)
        }) else { return }
        AXUIElementPerformAction(button.element, kAXPressAction as CFString)
    }

    func seek(to seconds: TimeInterval) {
        guard let root = applicationElement(),
              let slider = descendants(of: root).first(where: { $0.role == kAXSliderRole }) else { return }
        AXUIElementSetAttributeValue(slider.element, kAXValueAttribute as CFString, seconds as CFNumber)
    }

    func replay(_ track: MediaTrack) {
        guard isTrusted,
              let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first,
              let root = applicationElement() else { return }
        application.activate(options: [])

        let initial = descendants(of: root)
        guard let search = initial.first(where: {
            ($0.role == kAXTextFieldRole || $0.role == "AXSearchField") &&
                $0.semanticText.containsAny(["搜索", "search"])
        }) ?? initial.first(where: { $0.role == "AXSearchField" }) else { return }

        let query = [track.title, track.artist].filter { !$0.isEmpty }.joined(separator: " ")
        guard AXUIElementSetAttributeValue(
            search.element,
            kAXValueAttribute as CFString,
            query as CFString
        ) == .success else { return }
        _ = AXUIElementPerformAction(search.element, kAXConfirmAction as CFString)

        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            let candidates = descendants(of: root).filter {
                $0.role == kAXButtonRole || $0.role == kAXRowRole ||
                    $0.role == kAXCellRole || $0.role == kAXGroupRole
            }
            if let index = ReplayMatcher().bestMatch(
                title: track.title,
                artist: track.artist,
                candidates: candidates.map(\.semanticText)
            ) {
                let candidate = candidates[index]
                if AXUIElementPerformAction(candidate.element, kAXPressAction as CFString) == .success {
                    return
                }
                if let button = descendants(of: candidate.element, limit: 100)
                    .first(where: { $0.role == kAXButtonRole }) {
                    _ = AXUIElementPerformAction(button.element, kAXPressAction as CFString)
                    return
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func applicationElement() -> AXUIElement? {
        guard let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return nil
        }
        return AXUIElementCreateApplication(application.processIdentifier)
    }

    private func descendants(of root: AXUIElement, limit: Int = 2_000) -> [AXNode] {
        var result: [AXNode] = []
        var queue: [AXUIElement] = [root]
        while !queue.isEmpty && result.count < limit {
            let element = queue.removeFirst()
            let node = AXNode(element: element)
            result.append(node)
            queue.append(contentsOf: node.children)
        }
        return result
    }
}

private struct AXNode {
    let element: AXUIElement

    var role: String { stringAttribute(kAXRoleAttribute) }
    var semanticText: String {
        [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute, kAXValueAttribute]
            .map(stringAttribute)
            .joined(separator: " ")
            .lowercased()
    }
    var numberValue: Double? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success else {
            return nil
        }
        return (value as? NSNumber)?.doubleValue
    }
    var children: [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success else {
            return []
        }
        return value as? [AXUIElement] ?? []
    }

    private func stringAttribute(_ attribute: String) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return ""
        }
        return value as? String ?? ""
    }
}

private extension String {
    func containsAny(_ terms: [String]) -> Bool {
        terms.contains { contains($0.lowercased()) }
    }
}
