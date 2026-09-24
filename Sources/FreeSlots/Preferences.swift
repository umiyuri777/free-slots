import Foundation
import FreeSlotsCore

struct Preferences: Codable, Equatable {
    var rules: SlotRules = .default
    var style: OutputStyle = .perDay
    var ignoreAllDayEvents = true
    var excludedCalendarIDs: Set<String> = []

    private static let key = "preferences"

    static func load() -> Preferences {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let prefs = try? JSONDecoder().decode(Preferences.self, from: data)
        else { return Preferences() }
        return prefs
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
