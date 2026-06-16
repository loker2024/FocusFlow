import SwiftUI

@main
struct FocusFlowApp: App {
    @StateObject private var dataStore = DataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra("FocusFlow", systemImage: "timer") {
            MenuBarView()
                .environmentObject(dataStore)
        }
        .menuBarExtraStyle(.window)
    }
}
