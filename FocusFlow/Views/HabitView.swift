import SwiftUI

struct HabitView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddHabit = false
    @State private var newHabitName = ""
    @State private var newHabitIcon = "✅"
    @State private var newHabitFrequency: Habit.Frequency = .daily
    
    let icons = ["✅", "💪", "📚", "🏃", "💧", "🧘", "🎯", "💡", "🌟", "🔥"]
    
    var body: some View {
        AppPage(
            title: "习惯积累",
            subtitle: "小动作重复到足够多次，就会变成不用消耗意志力的自律系统。",
            icon: "leaf",
            actionTitle: "建立习惯",
            actionIcon: "plus",
            action: { showAddHabit = true }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    MetricCard(
                        title: "今日完成",
                        value: "\(todayCompletedCount)/\(dataStore.habits.count)",
                        caption: dataStore.habits.isEmpty ? "先建立一个微习惯" : "保持今天的闭环",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "最长连续",
                        value: "\(longestStreak) 天",
                        caption: "连续性会降低启动成本",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    MetricCard(
                        title: "完成率",
                        value: "\(completionRate)%",
                        caption: "今天的自律完成度",
                        icon: "chart.pie.fill",
                        color: .blue
                    )
                }
                
                List {
                    ForEach(dataStore.habits) { habit in
                        HabitRow(habit: habit)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            dataStore.deleteHabit(dataStore.habits[index])
                        }
                    }
                }
                .listStyle(.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.appStroke)
                )
                .overlay {
                    if dataStore.habits.isEmpty {
                        EmptyStateView(
                            icon: "leaf",
                            title: "还没有习惯",
                            message: "先建立一个小到不会抗拒的习惯，让积累开始发生。"
                        )
                    }
                }
                .frame(minHeight: 360)
            }
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitSheet(
                name: $newHabitName,
                icon: $newHabitIcon,
                frequency: $newHabitFrequency,
                icons: icons,
                onSave: {
                    let trimmedName = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty else { return }
                    
                    let habit = Habit(
                        name: trimmedName,
                        icon: newHabitIcon,
                        frequency: newHabitFrequency
                    )
                    dataStore.addHabit(habit)
                    resetNewHabit()
                    showAddHabit = false
                },
                onCancel: {
                    resetNewHabit()
                    showAddHabit = false
                }
            )
        }
    }
    
    private func resetNewHabit() {
        newHabitName = ""
        newHabitIcon = "✅"
        newHabitFrequency = .daily
    }
    
    private var todayCompletedCount: Int {
        dataStore.habits.filter { habit in
            habit.isCompleted()
        }.count
    }
    
    private var longestStreak: Int {
        dataStore.habits.map { $0.currentStreak() }.max() ?? 0
    }
    
    private var completionRate: Int {
        guard !dataStore.habits.isEmpty else { return 0 }
        return Int((Double(todayCompletedCount) / Double(dataStore.habits.count) * 100).rounded())
    }
}

struct HabitRow: View {
    @EnvironmentObject var dataStore: DataStore
    let habit: Habit
    
    var isCompletedToday: Bool {
        habit.isCompleted()
    }
    
    var streak: Int {
        habit.currentStreak()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Text(habit.icon)
                .font(.system(size: 32))
                .frame(width: 52, height: 52)
                .background(Color.appMutedAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                HStack {
                    Text(habit.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if streak > 0 {
                        Text("• 连续 \(streak) 天")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                dataStore.toggleHabit(habit)
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isCompletedToday ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

struct AddHabitSheet: View {
    @Binding var name: String
    @Binding var icon: String
    @Binding var frequency: Habit.Frequency
    let icons: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("建立新习惯")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("习惯动作")
                    .font(.headline)
                TextField("例如：睡前复盘 5 分钟", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("选择图标")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { self.icon = icon }) {
                            Text(icon)
                                .font(.system(size: 32))
                                .padding(8)
                                .background(self.icon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("频率")
                    .font(.headline)
                Picker("频率", selection: $frequency) {
                    ForEach(Habit.Frequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            HStack {
                Button("取消", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}
