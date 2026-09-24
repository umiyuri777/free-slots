import SwiftUI

@main
struct FreeSlotsApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(model)
        } label: {
            Image(systemName: "calendar.badge.clock")
        }
        .menuBarExtraStyle(.window)
    }
}
