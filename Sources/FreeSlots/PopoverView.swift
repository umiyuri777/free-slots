import FreeSlotsCore
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingSettings = false

    var body: some View {
        Group {
            if showingSettings {
                SettingsView { showingSettings = false }
            } else {
                main
            }
        }
        .frame(width: 320)
        // 常駐アプリなので、キーになるウインドウはこのポップオーバーだけ。開かれるたびに最新の予定で計算し直す。
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            model.popoverOpened()
        }
    }

    private var main: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !model.hasAccess {
                accessBanner
            }
            MonthGridView(
                month: model.displayedMonth,
                selected: model.selectedDays,
                onToggle: model.toggle
            )
            Divider()
            preview
            footer
        }
        .padding(14)
    }

    private var header: some View {
        HStack(spacing: 2) {
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button { model.moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left").frame(width: 20, height: 20)
            }
            Button("今日") { model.showCurrentMonth() }
            Button { model.moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right").frame(width: 20, height: 20)
            }
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape").frame(width: 20, height: 20)
            }
            .help("設定")
            .padding(.leading, 6)
        }
        .buttonStyle(.borderless)
    }

    private var monthTitle: String {
        let c = Calendar.current.dateComponents([.year, .month], from: model.displayedMonth)
        return "\(c.year!)年\(c.month!)月"
    }

    private var accessBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.accessStatus == .notDetermined {
                Text("カレンダーへのアクセスを許可すると、予定の入っていない時間を計算できます。")
                Button("アクセスを許可") { model.requestAccess() }
            } else {
                Text("カレンダーへのアクセスが許可されていません。システム設定で FreeSlots にフルアクセスを許可してください。")
                Button("システム設定を開く") { model.openPrivacySettings() }
            }
        }
        .font(.callout)
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { showingSettings = true } label: {
                Label(model.rulesSummary, systemImage: "clock")
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
            .help("条件を変更")

            if !model.hasAccess {
                Text("カレンダーへのアクセスを許可すると、ここに空き時間が表示されます")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 56)
            } else if model.selectedDays.isEmpty {
                Text("日付をクリックして選んでください（複数選べます）")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 56)
            } else if model.outputText.isEmpty {
                Text("選んだ日には条件に合う空き時間がありません")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, minHeight: 56)
            } else {
                ScrollView {
                    Text(model.outputText)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(minHeight: 56, maxHeight: 160)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.primary.opacity(0.1)))

                if !model.daysWithoutSlots.isEmpty {
                    Text(noSlotNote)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var noSlotNote: String {
        let days = model.daysWithoutSlots.map { SlotTextFormatter.dateLabel($0) }
        return "\(days.joined(separator: "、")) は空きがないため省きました"
    }

    private var footer: some View {
        HStack {
            Button("終了") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            Spacer()
            Button("クリア") { model.clearSelection() }
                .disabled(model.selectedDays.isEmpty)
            Button { model.copyToClipboard() } label: {
                Label(
                    model.justCopied ? "コピーしました" : "コピー",
                    systemImage: model.justCopied ? "checkmark" : "doc.on.doc"
                )
                .frame(minWidth: 96)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(model.outputText.isEmpty)
        }
    }
}
