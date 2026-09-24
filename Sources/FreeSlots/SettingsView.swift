import AppKit
import FreeSlotsCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    let onDone: () -> Void

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    private static let times = Array(stride(from: 0, through: 24 * 60, by: 30))

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDone) {
                    Label("戻る", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
                Spacer()
                Text("設定").font(.headline)
                Spacer()
                // タイトルを中央に置くための重し
                Label("戻る", systemImage: "chevron.left").hidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            Form {
                rulesSection
                styleSection
                calendarSections
                Section {
                    Toggle("ログイン時に起動", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, enabled in
                            LaunchAtLogin.set(enabled)
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                }
            }
            .formStyle(.grouped)
            .frame(height: 480)
        }
    }

    // MARK: - 空き時間の条件

    private var rulesSection: some View {
        Section("空き時間の条件") {
            Picker("開始", selection: dayStart) {
                ForEach(Self.times.dropLast(), id: \.self) { Text(SlotTextFormatter.timeLabel($0)).tag($0) }
            }
            Picker("終了", selection: $model.prefs.rules.dayEndMinutes) {
                ForEach(Self.times.filter { $0 > model.prefs.rules.dayStartMinutes }, id: \.self) {
                    Text(SlotTextFormatter.timeLabel($0)).tag($0)
                }
            }
            Picker("最短の長さ", selection: $model.prefs.rules.minimumMinutes) {
                ForEach([30, 60, 90, 120], id: \.self) { Text("\($0)分").tag($0) }
            }
            Picker("時刻の刻み", selection: $model.prefs.rules.stepMinutes) {
                ForEach([15, 30, 60], id: \.self) { Text("\($0)分").tag($0) }
            }
            Picker("予定の前後の余白", selection: $model.prefs.rules.bufferMinutes) {
                ForEach([0, 15, 30, 60], id: \.self) { Text($0 == 0 ? "なし" : "\($0)分").tag($0) }
            }
            Toggle("終日の予定は無視する", isOn: $model.prefs.ignoreAllDayEvents)
        }
    }

    /// 開始を終了より後にしたら、終了を 1 時間後にずらす
    private var dayStart: Binding<Int> {
        Binding(
            get: { model.prefs.rules.dayStartMinutes },
            set: { start in
                var rules = model.prefs.rules
                rules.dayStartMinutes = start
                if rules.dayEndMinutes <= start {
                    rules.dayEndMinutes = min(start + 60, 24 * 60)
                }
                model.prefs.rules = rules
            }
        )
    }

    // MARK: - 出力形式

    private var styleSection: some View {
        Section("出力形式") {
            Picker("出力形式", selection: $model.prefs.style) {
                Text("1日1行").tag(OutputStyle.perDay)
                Text("1枠1行").tag(OutputStyle.perSlot)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(styleExample)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var styleExample: String {
        switch model.prefs.style {
        case .perDay:
            "・9月25日(金) 10:00〜12:00、14:00〜18:00"
        case .perSlot:
            "・9月25日(金) 10:00〜12:00\n・9月25日(金) 14:00〜18:00"
        }
    }

    // MARK: - 対象カレンダー

    @ViewBuilder
    private var calendarSections: some View {
        let groups = groupedCalendars
        if groups.isEmpty {
            Section("対象カレンダー") {
                Text("カレンダーが見つかりません")
                    .foregroundStyle(.secondary)
            }
        }
        ForEach(groups, id: \.source) { group in
            Section(group.source) {
                ForEach(group.calendars) { info in
                    Toggle(isOn: included(info.id)) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(nsColor: info.color))
                                .frame(width: 8, height: 8)
                            Text(info.title)
                        }
                    }
                }
            }
        }
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Google カレンダーが一覧にない場合は、システム設定の「インターネットアカウント」で Google アカウントを追加し、「カレンダー」をオンにしてください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("インターネットアカウントを開く") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension")!
                    )
                }
                .font(.caption)
            }
        }
    }

    private var groupedCalendars: [(source: String, calendars: [CalendarInfo])] {
        var order: [String] = []
        var bySource: [String: [CalendarInfo]] = [:]
        for info in model.calendars {
            if bySource[info.sourceTitle] == nil { order.append(info.sourceTitle) }
            bySource[info.sourceTitle, default: []].append(info)
        }
        return order.map { ($0, bySource[$0]!) }
    }

    private func included(_ id: String) -> Binding<Bool> {
        Binding(
            get: { !model.prefs.excludedCalendarIDs.contains(id) },
            set: { model.setCalendar(id, included: $0) }
        )
    }
}
