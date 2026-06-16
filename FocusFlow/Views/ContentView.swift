import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab: Tab = .pomodoro
    
    enum Tab: String, CaseIterable {
        case pomodoro = "专注训练"
        case timeTracker = "时间账本"
        case tasks = "行动清单"
        case workLog = "每日复盘"
        case habits = "习惯积累"
        case goals = "长期目标"
        case countdown = "关键日期"
        
        var icon: String {
            switch self {
            case .pomodoro: return "timer"
            case .timeTracker: return "chart.bar.doc.horizontal"
            case .tasks: return "checklist"
            case .workLog: return "book.closed"
            case .habits: return "leaf"
            case .goals: return "target"
            case .countdown: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("FocusFlow")
            .navigationSplitViewColumnWidth(min: 150, ideal: 180)
        } detail: {
            Group {
                switch selectedTab {
                case .pomodoro:
                    PomodoroView()
                case .timeTracker:
                    TimeTrackerView()
                case .tasks:
                    TaskListView()
                case .workLog:
                    WorkLogView()
                case .habits:
                    HabitView()
                case .goals:
                    GoalView()
                case .countdown:
                    CountdownView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
