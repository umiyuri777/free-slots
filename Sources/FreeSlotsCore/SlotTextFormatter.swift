import Foundation

public enum OutputStyle: String, Codable, CaseIterable, Sendable {
    /// ・9月25日(木) 10:00〜12:00、14:00〜18:00
    case perDay
    /// ・9月25日(木) 10:00〜12:00
    /// ・9月25日(木) 14:00〜18:00
    case perSlot
}

public enum SlotTextFormatter {
    private static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    /// メールに貼り付ける形のテキストにする。空きのない日は出力しない。
    public static func text(
        for days: [DaySlots],
        style: OutputStyle,
        calendar: Calendar = .current
    ) -> String {
        var lines: [String] = []
        for entry in days.sorted(by: { $0.day < $1.day }) where !entry.slots.isEmpty {
            let date = dateLabel(entry.day, calendar: calendar)
            let ranges = entry.slots.map { rangeLabel($0, on: entry.day, calendar: calendar) }
            switch style {
            case .perDay:
                lines.append("・\(date) \(ranges.joined(separator: "、"))")
            case .perSlot:
                lines += ranges.map { "・\(date) \($0)" }
            }
        }
        return lines.joined(separator: "\n")
    }

    /// 9月25日(木)
    public static func dateLabel(_ day: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day, .weekday], from: day)
        return "\(c.month!)月\(c.day!)日(\(weekdaySymbols[c.weekday! - 1]))"
    }

    /// 10:00〜12:00。その日の 0:00 からの経過で表すので、日付をまたぐ終端は 24:00 になる。
    public static func rangeLabel(_ slot: DateInterval, on day: Date, calendar: Calendar = .current) -> String {
        let midnight = calendar.startOfDay(for: day)
        let from = Int(slot.start.timeIntervalSince(midnight) / 60)
        let to = Int(slot.end.timeIntervalSince(midnight) / 60)
        return "\(timeLabel(from))〜\(timeLabel(to))"
    }

    /// 分数 → 9:00 / 24:00
    public static func timeLabel(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}
