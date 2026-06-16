import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab: Tab = .pomodoro
    
    enum Tab: String, CaseIterable {
        case pomodoro = "番茄钟"
        case timeTracker = "时间追踪"
        case tasks = "任务管理"
        case workLog = "工作日志"
        case habits = "打卡"
        case goals = "目标"
        case countdown = "倒数日"
        
        var icon: String {
            switch self {
            case .pomodoro: return "timer"
            case .timeTracker: return "clock"
            case .tasks: return "checklist"
            case .workLog: return "doc.text"
            case .habits: return "star"
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

