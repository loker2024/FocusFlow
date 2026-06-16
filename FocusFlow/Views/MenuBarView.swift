import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showPomodoro = false
    @State private var showQuickTask = false
    @State private var quickTaskTitle = ""
    
    var body: some View {
        VStack(spacing: 15) {
            // 标题
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("FocusFlow")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
            
            // 快速操作
            VStack(spacing: 10) {
                // 番茄钟快捷操作
                Button(action: { showPomodoro = true }) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                        Text("启动番茄钟")
                        Spacer()
                        Text("⌘P")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                
                // 快速添加任务
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                    TextField("快速添加任务...", text: $quickTaskTitle)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            if !quickTaskTitle.isEmpty {
                                let task = TaskItem(title: quickTaskTitle)
                                dataStore.addTask(task)
                                quickTaskTitle = ""
                            }
                        }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 今日统计
            VStack(alignment: .leading, spacing: 8) {
                Text("今日统计")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                HStack {
                    MenuStatItem(
                        icon: "timer",
                        value: "\(todayPomodoroCount)",
                        label: "番茄",
                        color: .green
                    )
                    
                    MenuStatItem(
                        icon: "checkmark.circle",
                        value: "\(todayCompletedTasks)",
                        label: "任务",
                        color: .blue
                    )
                    
                    MenuStatItem(
                        icon: "star",
                        value: "\(todayHabitCount)",
                        label: "打卡",
                        color: .orange
                    )
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 即将到来的事件
            VStack(alignment: .leading, spacing: 8) {
                Text("即将到来")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(upcomingEvents) { event in
                    HStack {
                        Text(event.icon)
                        Text(event.title)
                            .font(.subheadline)
                        Spacer()
                        Text("\(event.daysRemaining)天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // 打开主窗口
            Button(action: {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }) {
                HStack {
                    Image(systemName: "window")
                    Text("打开主窗口")
                    Spacer()
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            
            // 退出
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                    Text("退出")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .frame(width: 250)
    }
    
    private var todayPomodoroCount: Int {
        dataStore.pomodoroSessions.filter {
            Calendar.current.isDateInToday($0.startTime) && $0.isCompleted
        }.count
    }
    
    private var todayCompletedTasks: Int {
        dataStore.tasks.filter {
            $0.isCompleted && $0.completedAt != nil && Calendar.current.isDateInToday($0.completedAt!)
        }.count
    }
    
    private var todayHabitCount: Int {
        dataStore.habits.filter { habit in
            habit.records.contains { record in
                Calendar.current.isDateInToday(record.date) && record.isCompleted
            }
        }.count
    }
    
    private var upcomingEvents: [CountdownEvent] {
        dataStore.countdownEvents
            .filter { $0.daysRemaining > 0 }
            .sorted { $0.daysRemaining < $1.daysRemaining }
            .prefix(3)
            .map { $0 }
    }
}

struct MenuStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

