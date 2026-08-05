import Foundation

public struct ReplayMatcher {
    public init() {}

    public func bestMatch(title: String, artist: String, candidates: [String]) -> Int? {
        let normalizedTitle = normalize(title)
        let normalizedArtist = normalize(artist)
        guard !normalizedTitle.isEmpty else { return nil }

        return candidates.enumerated()
            .compactMap { index, candidate -> (Int, Int)? in
                let text = normalize(candidate)
                guard text.contains(normalizedTitle) else { return nil }
                let score = 2 + ((!normalizedArtist.isEmpty && text.contains(normalizedArtist)) ? 2 : 0)
                return (index, score)
            }
            .max { lhs, rhs in
                lhs.1 == rhs.1 ? lhs.0 > rhs.0 : lhs.1 < rhs.1
            }?
            .0
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .lowercased()
    }
}
