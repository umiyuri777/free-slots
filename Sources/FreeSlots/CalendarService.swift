import AppKit
import EventKit

/// 設定画面の一覧に出すカレンダー
struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let sourceTitle: String
    let color: NSColor
}

/// macOS のカレンダーデータベース（EventKit）の読み取り。
/// Google アカウントを「インターネットアカウント」に追加しておくと、Google カレンダーの予定もここに入ってくる。
@MainActor
final class CalendarService {
    private var store = EKEventStore()

    /// 予定やカレンダーが外部（Google 側の変更の同期など）で変わったとき
    var onChange: (() -> Void)?

    init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onChange?() }
        }
    }

    var status: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var hasAccess: Bool { status == .fullAccess }

    func requestAccess() async {
        NSApp.activate(ignoringOtherApps: true)
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        if granted {
            // 許可前に作ったストアはカレンダーを持っていないことがあるので作り直す
            store = EKEventStore()
        }
        onChange?()
    }

    /// Google などリモートのカレンダーに同期を促す（結果は EKEventStoreChanged で届く）
    func refreshRemoteSources() {
        guard hasAccess else { return }
        store.refreshSourcesIfNecessary()
    }

    func calendars() -> [CalendarInfo] {
        guard hasAccess else { return [] }
        return store.calendars(for: .event)
            .map {
                CalendarInfo(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source?.title ?? "その他",
                    color: $0.color
                )
            }
            .sorted { ($0.sourceTitle, $0.title) < ($1.sourceTitle, $1.title) }
    }

    /// `day` に入っている「埋まっている」時間帯
    func busyIntervals(
        on day: Date,
        excludedCalendarIDs: Set<String>,
        ignoreAllDayEvents: Bool,
        calendar: Calendar = .current
    ) -> [DateInterval] {
        guard hasAccess else { return [] }
        let included = store.calendars(for: .event)
            .filter { !excludedCalendarIDs.contains($0.calendarIdentifier) }
        // calendars に空配列を渡すと全カレンダー扱いになりうるので、ここで打ち切る
        guard !included.isEmpty else { return [] }

        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: included)

        return store.events(matching: predicate).compactMap { event -> DateInterval? in
            if ignoreAllDayEvents && event.isAllDay { return nil }
            // Google カレンダーで「予定なし（Free）」にしたもの・キャンセル・自分が辞退したものは空き扱い
            if event.availability == .free { return nil }
            if event.status == .canceled { return nil }
            if event.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined {
                return nil
            }
            guard let s = event.startDate, let e = event.endDate else { return nil }
            return DateInterval(start: s, end: max(s, e))
        }
    }
}
