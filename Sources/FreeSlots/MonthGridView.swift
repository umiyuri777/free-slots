import SwiftUI

/// 日曜始まりの月カレンダー。日付をクリックすると選択をトグルする。過去の日は選べない。
struct MonthGridView: View {
    let month: Date
    let selected: Set<Date>
    let onToggle: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let today = calendar.startOfDay(for: Date())
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(1...7, id: \.self) { weekday in
                Text(weekdaySymbols[weekday - 1])
                    .font(.caption)
                    .foregroundStyle(Self.weekdayColor(weekday) ?? .secondary)
                    .frame(height: 18)
            }
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        number: calendar.component(.day, from: day),
                        weekday: calendar.component(.weekday, from: day),
                        isToday: day == today,
                        isPast: day < today,
                        isSelected: selected.contains(day)
                    ) {
                        onToggle(day)
                    }
                } else {
                    Color.clear.frame(height: DayCell.size)
                }
            }
        }
    }

    /// 6 週分（42 マス）。月によって高さが変わらないように常に同じ数にする。
    private var cells: [Date?] {
        guard
            let first = calendar.dateInterval(of: .month, for: month)?.start,
            let days = calendar.range(of: .day, in: .month, for: first)
        else { return [] }
        let leading = calendar.component(.weekday, from: first) - 1
        var cells: [Date?] = Array(repeating: nil, count: leading)
        cells += days.map { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
        cells += Array(repeating: nil, count: max(0, 42 - cells.count))
        return cells
    }

    static func weekdayColor(_ weekday: Int) -> Color? {
        switch weekday {
        case 1: .red
        case 7: .blue
        default: nil
        }
    }
}

private struct DayCell: View {
    static let size: CGFloat = 30

    let number: Int
    let weekday: Int
    let isToday: Bool
    let isPast: Bool
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 13, weight: isToday ? .bold : .regular).monospacedDigit())
                .foregroundStyle(foreground)
                .frame(width: Self.size, height: Self.size)
                .background {
                    Circle().fill(background)
                }
                .overlay {
                    if isToday && !isSelected {
                        Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isPast)
        .onHover { hovering = $0 && !isPast }
    }

    private var foreground: Color {
        if isSelected { return .white }
        if isPast { return .secondary.opacity(0.5) }
        return MonthGridView.weekdayColor(weekday) ?? .primary
    }

    private var background: Color {
        if isSelected { return .accentColor }
        if hovering { return .primary.opacity(0.08) }
        return .clear
    }
}
