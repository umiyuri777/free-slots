import Foundation
import Testing
@testable import FreeSlotsCore

private let tokyo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

/// 2026-09-25 (金) の hh:mm
private func at(_ hour: Int, _ minute: Int = 0, day: Int = 25) -> Date {
    tokyo.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
}

private func event(_ h1: Int, _ m1: Int, _ h2: Int, _ m2: Int) -> DateInterval {
    DateInterval(start: at(h1, m1), end: at(h2, m2))
}

/// 前日の夜を「今」にして、今日判定の影響を受けないようにする
private let yesterday = at(20, day: 24)

private func labels(
    _ busy: [DateInterval],
    rules: SlotRules = .default,
    now: Date = yesterday
) -> [String] {
    FreeSlotCalculator
        .freeSlots(on: at(0), busy: busy, rules: rules, now: now, calendar: tokyo)
        .map { SlotTextFormatter.rangeLabel($0, on: at(0), calendar: tokyo) }
}

@Suite struct FreeSlotCalculatorTests {
    @Test func noEventsGivesWholeWindow() {
        #expect(labels([]) == ["9:00〜18:00"])
    }

    @Test func splitsAroundAnEvent() {
        #expect(labels([event(10, 0, 11, 0)]) == ["9:00〜10:00", "11:00〜18:00"])
    }

    @Test func dropsGapsShorterThanMinimum() {
        // 9:00〜9:30 は 60 分未満なので出ない
        #expect(labels([event(9, 30, 12, 0)]) == ["12:00〜18:00"])
    }

    @Test func roundsToStep() {
        // 10:45 終わり → 11:00 から、13:10 開始 → 13:00 まで
        #expect(labels([event(9, 0, 10, 45), event(13, 10, 18, 0)]) == ["11:00〜13:00"])
    }

    @Test func appliesBufferAroundEvents() {
        var rules = SlotRules.default
        rules.bufferMinutes = 30
        #expect(labels([event(12, 0, 13, 0)], rules: rules) == ["9:00〜11:30", "13:30〜18:00"])
    }

    @Test func mergesOverlappingEvents() {
        let busy = [event(10, 0, 12, 0), event(11, 0, 13, 0), event(12, 30, 14, 0)]
        #expect(labels(busy) == ["9:00〜10:00", "14:00〜18:00"])
    }

    @Test func ignoresEventsOutsideWindowAndClipsLongOnes() {
        let busy = [event(7, 0, 8, 0), event(8, 0, 10, 0), event(17, 0, 23, 0)]
        #expect(labels(busy) == ["10:00〜17:00"])
    }

    @Test func todayStartsFromNowRoundedUp() {
        #expect(labels([], now: at(10, 7)) == ["10:30〜18:00"])
    }

    @Test func pastDayHasNoSlots() {
        #expect(labels([], now: at(12, day: 26)).isEmpty)
    }

    @Test func fullyBookedDayHasNoSlots() {
        #expect(labels([event(8, 0, 19, 0)]).isEmpty)
    }

    @Test func windowCanRunUntilMidnight() {
        var rules = SlotRules.default
        rules.dayStartMinutes = 20 * 60
        rules.dayEndMinutes = 24 * 60
        #expect(labels([], rules: rules) == ["20:00〜24:00"])
    }
}

@Suite struct SlotTextFormatterTests {
    private let days = [
        DaySlots(day: at(0, day: 26), slots: [DateInterval(start: at(13, day: 26), end: at(17, day: 26))]),
        DaySlots(day: at(0), slots: [event(9, 0, 10, 0), event(14, 0, 18, 0)]),
        DaySlots(day: at(0, day: 27), slots: []),
    ]

    @Test func perDaySortsAndSkipsEmptyDays() {
        let text = SlotTextFormatter.text(for: days, style: .perDay, calendar: tokyo)
        #expect(text == """
        ・9月25日(金) 9:00〜10:00、14:00〜18:00
        ・9月26日(土) 13:00〜17:00
        """)
    }

    @Test func perSlotWritesOneLinePerSlot() {
        let text = SlotTextFormatter.text(for: days, style: .perSlot, calendar: tokyo)
        #expect(text == """
        ・9月25日(金) 9:00〜10:00
        ・9月25日(金) 14:00〜18:00
        ・9月26日(土) 13:00〜17:00
        """)
    }
}
