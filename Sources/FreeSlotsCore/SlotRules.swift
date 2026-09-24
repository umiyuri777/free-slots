import Foundation

/// 空き時間を「候補」とみなす条件。時刻はすべてその日の 0:00 からの分数。
public struct SlotRules: Codable, Equatable, Sendable {
    /// 候補にする時間帯の開始（例: 540 = 9:00）
    public var dayStartMinutes: Int
    /// 候補にする時間帯の終了（例: 1080 = 18:00。1440 = 24:00 まで指定可）
    public var dayEndMinutes: Int
    /// これより短い空きは候補にしない
    public var minimumMinutes: Int
    /// 開始は切り上げ・終了は切り捨てでこの刻みにそろえる（10:07 → 10:30 など）
    public var stepMinutes: Int
    /// 予定の前後に確保する余白（移動・準備の時間）
    public var bufferMinutes: Int

    public init(
        dayStartMinutes: Int,
        dayEndMinutes: Int,
        minimumMinutes: Int,
        stepMinutes: Int,
        bufferMinutes: Int
    ) {
        self.dayStartMinutes = dayStartMinutes
        self.dayEndMinutes = dayEndMinutes
        self.minimumMinutes = minimumMinutes
        self.stepMinutes = stepMinutes
        self.bufferMinutes = bufferMinutes
    }

    public static let `default` = SlotRules(
        dayStartMinutes: 9 * 60,
        dayEndMinutes: 18 * 60,
        minimumMinutes: 60,
        stepMinutes: 30,
        bufferMinutes: 0
    )
}

/// ある日と、その日の空き時間帯
public struct DaySlots: Equatable, Sendable {
    public var day: Date
    public var slots: [DateInterval]

    public init(day: Date, slots: [DateInterval]) {
        self.day = day
        self.slots = slots
    }
}
