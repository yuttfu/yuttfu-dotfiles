import Darwin
import Foundation
import YuttfuMediaCore

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

private func track(id: String, title: String, source: MediaSource = .qqMusic) -> MediaTrack {
    MediaTrack(
        source: source,
        sourceBundleID: source == .qqMusic ? "com.tencent.QQMusicMac" : "com.netease.163music",
        trackID: id,
        trackMID: "mid-\(id)",
        title: title,
        artist: "yuttfu",
        album: nil,
        duration: 180,
        artworkPath: nil
    )
}

private func snapshot(source: MediaSource, state: PlaybackState, observedAt: TimeInterval) -> MediaSnapshot {
    MediaSnapshot(
        track: track(id: source.rawValue, title: source.rawValue, source: source),
        elapsed: 12,
        playbackState: state,
        observedAt: Date(timeIntervalSince1970: observedAt),
        permissionState: .granted
    )
}

private struct TestContext {
    let directory: URL
    let historyURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        historyURL = directory.appendingPathComponent("media-history.json")
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

@objc(YuttfuFixtureSinger)
private final class FixtureSinger: NSObject, NSCoding {
    let name: String

    init(name: String) {
        self.name = name
    }

    required init?(coder: NSCoder) {
        nil
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
    }
}

@objc(YuttfuFixtureSong)
private final class FixtureSong: NSObject, NSCoding {
    required init?(coder: NSCoder) {
        nil
    }

    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(Int64(547_581_851), forKey: "songId")
        coder.encode("001TestSongMID", forKey: "song_Mid")
        coder.encode("测试歌曲", forKey: "songName")
        coder.encode("245", forKey: "song_Duration")
        coder.encode([FixtureSinger(name: "测试歌手")], forKey: "singerList")
        coder.encode("003TestAlbumMID", forKey: "albumMid")
    }
}

@objc(YuttfuFixtureList)
private final class FixtureList: NSObject, NSCoding {
    required init?(coder: NSCoder) {
        nil
    }

    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode([FixtureSong()], forKey: "ListData")
    }
}

private func qqMusicArchiveFixture() throws -> Data {
    NSKeyedArchiver.setClassName("ListBase", for: FixtureList.self)
    NSKeyedArchiver.setClassName("SongInfo", for: FixtureSong.self)
    NSKeyedArchiver.setClassName("SingerInfo", for: FixtureSinger.self)
    defer {
        NSKeyedArchiver.setClassName(nil, for: FixtureList.self)
        NSKeyedArchiver.setClassName(nil, for: FixtureSong.self)
        NSKeyedArchiver.setClassName(nil, for: FixtureSinger.self)
    }
    return try NSKeyedArchiver.archivedData(withRootObject: FixtureList(), requiringSecureCoding: false)
}

private let tests: [(String, () throws -> Void)] = [
    ("recording moves a duplicate track to the front", {
        let context = try TestContext()
        defer { context.remove() }
        let store = HistoryStore(fileURL: context.historyURL, maximumEntries: 6)
        try store.record(track(id: "1", title: "第一首"), observedAt: Date(timeIntervalSince1970: 1))
        try store.record(track(id: "2", title: "第二首"), observedAt: Date(timeIntervalSince1970: 2))
        try store.record(track(id: "1", title: "第一首"), observedAt: Date(timeIntervalSince1970: 3))

        let entries = try store.load()
        try expect(entries.map(\.track.title) == ["第一首", "第二首"], "duplicate was not moved")
        try expect(entries.first?.observedAt == Date(timeIntervalSince1970: 3), "timestamp was not refreshed")
    }),
    ("recording keeps only six recent tracks", {
        let context = try TestContext()
        defer { context.remove() }
        let store = HistoryStore(fileURL: context.historyURL, maximumEntries: 6)
        for index in 1...7 {
            try store.record(
                track(id: String(index), title: "歌曲\(index)"),
                observedAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        let entries = try store.load()
        try expect(entries.count == 6, "history exceeded six tracks")
        try expect(entries.map(\.track.title) == ["歌曲7", "歌曲6", "歌曲5", "歌曲4", "歌曲3", "歌曲2"], "history order is wrong")
    }),
    ("history persists across store instances", {
        let context = try TestContext()
        defer { context.remove() }
        try HistoryStore(fileURL: context.historyURL, maximumEntries: 6).record(
            track(id: "持久化", title: "重启后仍存在"),
            observedAt: Date(timeIntervalSince1970: 10)
        )

        let restored = try HistoryStore(fileURL: context.historyURL, maximumEntries: 6).load()
        try expect(restored.first?.track.title == "重启后仍存在", "history did not persist")
        try expect(restored.first?.track.artist == "yuttfu", "Unicode metadata changed")
    }),
    ("corrupt history is backed up and reset", {
        let context = try TestContext()
        defer { context.remove() }
        try Data("not-json".utf8).write(to: context.historyURL)
        let store = HistoryStore(fileURL: context.historyURL, maximumEntries: 6)

        let recovered = try store.load()
        try expect(recovered == [], "corrupt history was not reset")
        let backups = try FileManager.default.contentsOfDirectory(
            at: context.directory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("media-history.json.corrupt-") }
        try expect(backups.count == 1, "corrupt history backup was not created")
    }),
    ("QQ Music archive parser reads stable song metadata", {
        let tracks = try QQMusicArchiveParser().parse(data: qqMusicArchiveFixture())
        try expect(tracks.count == 1, "fixture track was not parsed")
        let parsed = try tracks.first.unwrap(or: "parsed track is missing")
        try expect(parsed.source == .qqMusic, "source is not QQ Music")
        try expect(parsed.trackID == "547581851", "songId was not parsed")
        try expect(parsed.trackMID == "001TestSongMID", "song_Mid was not parsed")
        try expect(parsed.title == "测试歌曲", "songName was not parsed")
        try expect(parsed.artist == "测试歌手", "singerList was not parsed")
        try expect(parsed.duration == 245, "duration was not parsed")
        try expect(
            parsed.artworkURL == "https://y.qq.com/music/photo_new/T002R300x300M000003TestAlbumMID.jpg",
            "albumMid artwork URL was not derived"
        )
    }),
    ("QQ Music real archive parses when explicitly supplied", {
        guard let path = ProcessInfo.processInfo.environment["YUTTFU_QQ_ARCHIVE_FIXTURE"] else {
            return
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let tracks = try QQMusicArchiveParser().parse(data: data)
        try expect(!tracks.isEmpty, "real archive did not yield any tracks")
        try expect(tracks.allSatisfy { !$0.title.isEmpty }, "real archive yielded an empty title")
    }),
    ("replay matcher prefers a result containing title and artist", {
        let candidates = [
            "播放 测试歌曲 其他歌手",
            "测试歌曲 - 测试歌手 专辑",
            "测试歌手的热门歌曲",
        ]
        let match = ReplayMatcher().bestMatch(
            title: "测试歌曲",
            artist: "测试歌手",
            candidates: candidates
        )
        try expect(match == 1, "semantic replay chose the wrong result")
        try expect(
            ReplayMatcher().bestMatch(title: "不存在", artist: "测试歌手", candidates: candidates) == nil,
            "replay accepted a candidate without the title"
        )
    }),
    ("playing QQ Music wins source arbitration", {
        let selected = SourceArbiter().select(
            qqMusic: snapshot(source: .qqMusic, state: .playing, observedAt: 1),
            netease: snapshot(source: .netease, state: .playing, observedAt: 2)
        )
        try expect(selected?.track.source == .qqMusic, "playing QQ Music was not selected")
    }),
    ("playing Netease replaces paused QQ Music", {
        let selected = SourceArbiter().select(
            qqMusic: snapshot(source: .qqMusic, state: .paused, observedAt: 2),
            netease: snapshot(source: .netease, state: .playing, observedAt: 3)
        )
        try expect(selected?.track.source == .netease, "playing Netease did not replace paused QQ Music")
    }),
    ("most recently observed paused source remains visible", {
        let selected = SourceArbiter().select(
            qqMusic: snapshot(source: .qqMusic, state: .paused, observedAt: 5),
            netease: snapshot(source: .netease, state: .paused, observedAt: 4)
        )
        try expect(selected?.track.source == .qqMusic, "most recent paused source was not selected")
    }),
    ("media URL command parser accepts supported commands", {
        let parser = MediaCommandParser()
        try expect(parser.parse(URL(string: "yuttfu-media://toggle-panel")!) == .togglePanel, "toggle-panel was not parsed")
        try expect(parser.parse(URL(string: "yuttfu-media://play-pause")!) == .playPause, "play-pause was not parsed")
        try expect(parser.parse(URL(string: "yuttfu-media://previous")!) == .previous, "previous was not parsed")
        try expect(parser.parse(URL(string: "yuttfu-media://next")!) == .next, "next was not parsed")
        try expect(parser.parse(URL(string: "https://example.com")!) == nil, "foreign scheme was accepted")
    }),
    ("player presentation formats progress and disables unknown elapsed time", {
        let known = PlayerPresentation(
            snapshot: MediaSnapshot(
                track: MediaTrack(
                    source: .qqMusic,
                    sourceBundleID: "com.tencent.QQMusicMac",
                    trackID: "1",
                    trackMID: "mid-1",
                    title: "一首歌",
                    artist: "歌手",
                    album: nil,
                    duration: 258,
                    artworkPath: nil
                ),
                elapsed: 102,
                playbackState: .playing,
                observedAt: Date(),
                permissionState: .granted
            )
        )
        try expect(known.elapsedText == "01:42", "elapsed time format is wrong")
        try expect(known.durationText == "04:18", "duration format is wrong")
        try expect(known.progressEnabled, "known progress should be interactive")
        try expect(abs(known.progress - (102.0 / 258.0)) < 0.0001, "progress ratio is wrong")

        let unknown = PlayerPresentation(
            snapshot: MediaSnapshot(
                track: known.snapshot.track,
                elapsed: nil,
                playbackState: .paused,
                observedAt: Date(),
                permissionState: .missing
            )
        )
        try expect(unknown.elapsedText == "--:--", "unknown elapsed time was fabricated")
        try expect(!unknown.progressEnabled, "unknown progress should be disabled")
    }),
    ("QQ Music open-file parser prefers the active read handle", {
        let output = """
        QQMusic 1 yuttfu txt REG 1,17 10 1 /tmp/QQMusicMac/iMusic/AA/111-13.mflac
        QQMusic 1 yuttfu 45u REG 1,17 10 2 /tmp/QQMusicMac/iDownloadProxy/ABC.mflac
        QQMusic 1 yuttfu 117r REG 1,17 10 3 /tmp/QQMusicMac/iMusic/EA/123456789-13.mflac
        """
        try expect(QQMusicOpenFileParser().currentSongID(from: output) == "123456789", "active song ID was not selected")
    }),
    ("QQ Music snapshot builder combines queue and accessibility state", {
        let tracks = [track(id: "123456789", title: "当前歌曲")]
        let snapshot = QQMusicSnapshotBuilder().build(
            tracks: tracks,
            currentSongID: "123456789",
            accessibility: QQMusicAccessibilityState(
                playbackState: .playing,
                elapsed: 42,
                permissionState: .granted
            ),
            observedAt: Date(timeIntervalSince1970: 8)
        )
        try expect(snapshot?.track.title == "当前歌曲", "current queue track was not matched")
        try expect(snapshot?.playbackState == .playing, "playback state was not preserved")
        try expect(snapshot?.elapsed == 42, "elapsed time was not preserved")
    }),
    ("QQ Music snapshot builder does not fabricate state without permission", {
        let snapshot = QQMusicSnapshotBuilder().build(
            tracks: [track(id: "1", title: "仍可展示")],
            currentSongID: "1",
            accessibility: nil,
            observedAt: Date(timeIntervalSince1970: 9)
        )
        try expect(snapshot?.track.title == "仍可展示", "track disappeared without permission")
        try expect(snapshot?.playbackState == .paused, "playing state was fabricated")
        try expect(snapshot?.elapsed == nil, "elapsed time was fabricated")
        try expect(snapshot?.permissionState == .missing, "missing permission was not exposed")
    }),
]

private extension Optional {
    func unwrap(or message: String) throws -> Wrapped {
        guard let self else {
            throw TestFailure(description: message)
        }
        return self
    }
}

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS: \(name)")
    } catch {
        failures += 1
        fputs("FAIL: \(name): \(error)\n", stderr)
    }
}

print("\(tests.count - failures) passed, \(failures) failed")
exit(failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
