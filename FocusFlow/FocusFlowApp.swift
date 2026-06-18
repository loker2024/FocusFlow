import SwiftUI

@main
@MainActor
struct FocusFlowApp: App {
    @StateObject private var dataStore: DataStore
    @StateObject private var pomodoroTimer: PomodoroTimerController

    init() {
        let sharedDataStore = DataStore.shared
        _dataStore = StateObject(wrappedValue: sharedDataStore)
        _pomodoroTimer = StateObject(wrappedValue: PomodoroTimerController(dataStore: sharedDataStore))
    }

    var body: some Scene {
        Window("FocusFlow", id: "main") {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(pomodoroTimer)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)

        MenuBarExtra("FocusFlow", systemImage: "timer") {
            MenuBarView()
                .environmentObject(dataStore)
                .environmentObject(pomodoroTimer)
        }
        .menuBarExtraStyle(.window)
    }
}
