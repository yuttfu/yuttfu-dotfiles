import Foundation

public struct MonthDay: Equatable, Sendable {
    public let date: Date
    public let day: Int
    public let isInDisplayedMonth: Bool
    public let isToday: Bool

    public init(date: Date, day: Int, isInDisplayedMonth: Bool, isToday: Bool) {
        self.date = date
        self.day = day
        self.isInDisplayedMonth = isInDisplayedMonth
        self.isToday = isToday
    }
}

public enum MonthGrid {
    public static func make(
        year: Int,
        month: Int,
        calendar: Calendar,
        today: Date
    ) -> [MonthDay] {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        guard let firstCell = calendar.date(byAdding: .day, value: -leadingDays, to: firstOfMonth) else {
            return []
        }

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstCell) else {
                return nil
            }
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return MonthDay(
                date: date,
                day: components.day ?? 0,
                isInDisplayedMonth: components.year == year && components.month == month,
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }
    }
}
