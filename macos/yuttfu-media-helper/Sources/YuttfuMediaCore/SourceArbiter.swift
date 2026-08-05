import Foundation

public struct SourceArbiter {
    public init() {}

    public func select(
        qqMusic: MediaSnapshot?,
        netease: MediaSnapshot?
    ) -> MediaSnapshot? {
        if qqMusic?.playbackState == .playing {
            return qqMusic
        }
        if netease?.playbackState == .playing {
            return netease
        }

        return [qqMusic, netease]
            .compactMap { $0 }
            .filter { $0.playbackState == .paused }
            .max { $0.observedAt < $1.observedAt }
    }
}
