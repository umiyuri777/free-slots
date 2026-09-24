import Foundation

public enum FreeSlotCalculator {
    /// `day` の候補時間帯から `busy` を除いた空き時間を返す。
    ///
    /// - 予定は前後に `bufferMinutes` ずつ広げてから差し引く
    /// - `now` より前の時間は候補にしない（今日を選んだ場合に効く）
    /// - 各空きは `stepMinutes` 刻みに丸め、`minimumMinutes` 未満になったものは捨てる
    public static func freeSlots(
        on day: Date,
        busy: [DateInterval],
        rules: SlotRules,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [DateInterval] {
        let midnight = calendar.startOfDay(for: day)
        guard
            let windowStart = calendar.date(byAdding: .minute, value: rules.dayStartMinutes, to: midnight),
            let windowEnd = calendar.date(byAdding: .minute, value: rules.dayEndMinutes, to: midnight)
        else { return [] }

        let start = max(windowStart, now)
        guard start < windowEnd else { return [] }

        let buffer = TimeInterval(rules.bufferMinutes * 60)
        let blocked = busy
            .map { (start: $0.start - buffer, end: $0.end + buffer) }
            .filter { $0.end > start && $0.start < windowEnd }
            .sorted { $0.start < $1.start }

        var gaps: [(start: Date, end: Date)] = []
        var cursor = start
        for block in blocked {
            if block.start > cursor {
                gaps.append((cursor, block.start))
            }
            cursor = max(cursor, block.end)
        }
        if cursor < windowEnd {
            gaps.append((cursor, windowEnd))
        }

        let step = TimeInterval(max(rules.stepMinutes, 1) * 60)
        let minimum = TimeInterval(rules.minimumMinutes * 60)
        return gaps.compactMap { gap in
            // その日の 0:00 基準で丸めるので、刻みは常に 9:00, 9:30, ... のような壁時計の時刻にそろう
            let from = (gap.start.timeIntervalSince(midnight) / step).rounded(.up) * step
            let to = (gap.end.timeIntervalSince(midnight) / step).rounded(.down) * step
            guard to > from, to - from >= minimum else { return nil }
            return DateInterval(start: midnight + from, end: midnight + to)
        }
    }
}
