import Foundation

public enum QQMusicArchiveError: Error {
    case invalidRoot(String)
}

public struct QQMusicArchiveParser {
    public init() {}

    public func parse(data: Data) throws -> [MediaTrack] {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        unarchiver.setClass(QQArchivedList.self, forClassName: "ListBase")
        unarchiver.setClass(QQArchivedSong.self, forClassName: "SongInfo")
        unarchiver.setClass(QQArchivedSinger.self, forClassName: "SingerInfo")
        unarchiver.setClass(QQArchivedAlbum.self, forClassName: "AlbumInfo")
        defer { unarchiver.finishDecoding() }

        let decodedRoot = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
            ?? unarchiver.decodeObject(forKey: "PlayingList")
        guard let list = decodedRoot as? QQArchivedList else {
            let typeName = decodedRoot.map { String(reflecting: type(of: $0)) }
                ?? unarchiver.error.map(String.init(describing:))
                ?? "nil"
            throw QQMusicArchiveError.invalidRoot(typeName)
        }

        return list.songs.compactMap { song in
            guard !song.title.isEmpty else { return nil }
            let albumMID = song.albumMID.nilIfEmpty ?? song.album?.mid.nilIfEmpty
            return MediaTrack(
                source: .qqMusic,
                sourceBundleID: "com.tencent.QQMusicMac",
                trackID: song.songID == 0 ? nil : String(song.songID),
                trackMID: song.songMID.nilIfEmpty,
                title: song.title,
                artist: song.singers.map(\.name).filter { !$0.isEmpty }.joined(separator: " / "),
                album: song.album?.name.nilIfEmpty,
                duration: song.duration,
                artworkPath: nil,
                artworkURL: albumMID.map {
                    "https://y.qq.com/music/photo_new/T002R300x300M000\($0).jpg"
                }
            )
        }
    }
}

@objc(YuttfuQQArchivedList)
private final class QQArchivedList: NSObject, NSCoding {
    let songs: [QQArchivedSong]

    required init?(coder: NSCoder) {
        songs = coder.decodeObject(forKey: "ListData") as? [QQArchivedSong] ?? []
    }

    func encode(with coder: NSCoder) {}
}

@objc(YuttfuQQArchivedSong)
private final class QQArchivedSong: NSObject, NSCoding {
    let songID: Int64
    let songMID: String
    let title: String
    let duration: TimeInterval?
    let singers: [QQArchivedSinger]
    let album: QQArchivedAlbum?
    let albumMID: String

    required init?(coder: NSCoder) {
        songID = coder.decodeInt64(forKey: "songId")
        songMID = coder.string(forKeys: ["song_Mid", "songMid"])
        title = coder.string(forKeys: ["songName", "name"])
        duration = coder.timeInterval(forKeys: ["song_Duration", "duration"])
        singers = coder.decodeObject(forKey: "singerList") as? [QQArchivedSinger] ?? []
        album = coder.decodeObject(forKey: "albumInfo") as? QQArchivedAlbum
        albumMID = coder.string(forKeys: ["albumMid", "album_Mid"])
    }

    func encode(with coder: NSCoder) {}
}

@objc(YuttfuQQArchivedSinger)
private final class QQArchivedSinger: NSObject, NSCoding {
    let name: String

    required init?(coder: NSCoder) {
        name = coder.string(forKeys: ["name", "singerName"])
    }

    func encode(with coder: NSCoder) {}
}

@objc(YuttfuQQArchivedAlbum)
private final class QQArchivedAlbum: NSObject, NSCoding {
    let name: String
    let mid: String

    required init?(coder: NSCoder) {
        name = coder.string(forKeys: ["name", "albumName"])
        mid = coder.string(forKeys: ["albumMid", "album_Mid", "mid"])
    }

    func encode(with coder: NSCoder) {}
}

private extension NSCoder {
    func string(forKeys keys: [String]) -> String {
        for key in keys where containsValue(forKey: key) {
            if let value = decodeObject(forKey: key) as? String {
                return value
            }
            if let value = decodeObject(forKey: key) as? NSNumber {
                return value.stringValue
            }
        }
        return ""
    }

    func timeInterval(forKeys keys: [String]) -> TimeInterval? {
        for key in keys where containsValue(forKey: key) {
            if let value = decodeObject(forKey: key) as? NSNumber {
                return value.doubleValue
            }
            if let value = decodeObject(forKey: key) as? String,
               let duration = TimeInterval(value) {
                return duration
            }
            let value = decodeDouble(forKey: key)
            if value > 0 {
                return value
            }
        }
        return nil
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
