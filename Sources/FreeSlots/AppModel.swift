import AppKit
import EventKit
import FreeSlotsCore

@MainActor
final class AppModel: ObservableObject {
    @Published var displayedMonth: Date
    @Published var selectedDays: Set<Date> = [] {
        didSet { recompute() }
    }
    @Published var prefs: Preferences {
        didSet {
            prefs.save()
            recompute()
        }
    }
    @Published private(set) var results: [DaySlots] = []
    @Published private(set) var accessStatus: EKAuthorizationStatus
    @Published private(set) var calendars: [CalendarInfo] = []
    @Published private(set) var justCopied = false

    private let events = CalendarService()
    private let calendar = Calendar.autoupdatingCurrent
    private var copiedResetTask: Task<Void, Never>?

    init() {
        displayedMonth = Date()
        prefs = Preferences.load()
        accessStatus = events.status
        events.onChange = { [weak self] in self?.reloadFromStore() }
        reloadFromStore()

        if accessStatus == .notDetermined {
            Task { await events.requestAccess() }
        }
    }

    // MARK: - 表示

    var hasAccess: Bool { accessStatus == .fullAccess }

    /// 予定を読めないうちは「全部空き」に見えてしまうので何も出さない
    var outputText: String {
        guard hasAccess else { return "" }
        return SlotTextFormatter.text(for: results, style: prefs.style, calendar: calendar)
    }

    /// 選んだけれど条件に合う空きがなかった日
    var daysWithoutSlots: [Date] {
        results.filter(\.slots.isEmpty).map(\.day).sorted()
    }

    var rulesSummary: String {
        let r = prefs.rules
        var parts = [
            "\(SlotTextFormatter.timeLabel(r.dayStartMinutes))〜\(SlotTextFormatter.timeLabel(r.dayEndMinutes))",
            "\(r.minimumMinutes)分以上",
        ]
        if r.bufferMinutes > 0 { parts.append("前後\(r.bufferMinutes)分空け") }
        return parts.joined(separator: "・")
    }

    // MARK: - 操作

    func toggle(_ day: Date) {
        let key = calendar.startOfDay(for: day)
        if selectedDays.contains(key) {
            selectedDays.remove(key)
        } else {
            selectedDays.insert(key)
        }
    }

    func clearSelection() {
        selectedDays = []
    }

    func moveMonth(by value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = next
        }
    }

    func showCurrentMonth() {
        displayedMonth = Date()
    }

    func copyToClipboard() {
        let text = outputText
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        justCopied = true
        copiedResetTask?.cancel()
        copiedResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.justCopied = false
        }
    }

    func requestAccess() {
        Task { await events.requestAccess() }
    }

    func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!
        NSWorkspace.shared.open(url)
    }

    func setCalendar(_ id: String, included: Bool) {
        if included {
            prefs.excludedCalendarIDs.remove(id)
        } else {
            prefs.excludedCalendarIDs.insert(id)
        }
    }

    /// ポップオーバーを開くたびに呼ぶ。日付が変わっていれば過去の選択を外し、「今日」の空きを今の時刻から計算し直す。
    func popoverOpened() {
        let today = calendar.startOfDay(for: Date())
        let stillValid = selectedDays.filter { $0 >= today }
        if stillValid != selectedDays {
            selectedDays = stillValid
        }
        if calendar.compare(displayedMonth, to: today, toGranularity: .month) == .orderedAscending {
            displayedMonth = today
        }
        events.refreshRemoteSources()
        reloadFromStore()
    }

    // MARK: - 内部

    private func reloadFromStore() {
        accessStatus = events.status
        calendars = events.calendars()
        recompute()
    }

    private func recompute() {
        let now = Date()
        results = selectedDays.sorted().map { day in
            let busy = events.busyIntervals(
                on: day,
                excludedCalendarIDs: prefs.excludedCalendarIDs,
                ignoreAllDayEvents: prefs.ignoreAllDayEvents,
                calendar: calendar
            )
            let slots = FreeSlotCalculator.freeSlots(
                on: day, busy: busy, rules: prefs.rules, now: now, calendar: calendar
            )
            return DaySlots(day: day, slots: slots)
        }
    }
}
