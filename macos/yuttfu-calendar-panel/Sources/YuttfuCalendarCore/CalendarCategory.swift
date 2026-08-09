public enum CalendarCategory: String, CaseIterable, Codable, Sendable {
    case acm
    case ai
    case course
    case personal

    public var displayName: String {
        switch self {
        case .acm: "ACM"
        case .ai: "AI"
        case .course: "课程/考试"
        case .personal: "个人"
        }
    }
}
