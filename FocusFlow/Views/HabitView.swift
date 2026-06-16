import SwiftUI

struct HabitView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddHabit = false
    @State private var newHabitName = ""
    @State private var newHabitIcon = "✅"
    @State private var newHabitFrequency: Habit.Frequency = .daily
    
    let icons = ["✅", "💪", "📚", "🏃", "💧", "🧘", "🎯", "💡", "🌟", "🔥"]
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            HStack {
                Text("习惯打卡")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showAddHabit = true }) {
                    Label("添加习惯", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 今日打卡统计
            HStack {
                HabitStatCard(
                    title: "今日打卡",
                    value: "\(todayCompletedCount)/\(dataStore.habits.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                HabitStatCard(
                    title: "连续天数",
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            // 习惯列表
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
        }
        .padding(40)
        .sheet(isPresented: $showAddHabit) {
            AddHabitSheet(
                name: $newHabitName,
                icon: $newHabitIcon,
                frequency: $newHabitFrequency,
                icons: icons,
                onSave: {
                    let habit = Habit(
                        name: newHabitName,
                        icon: newHabitIcon,
                        frequency: newHabitFrequency
                    )
                    dataStore.addHabit(habit)
                    newHabitName = ""
                    newHabitIcon = "✅"
                    newHabitFrequency = .daily
                    showAddHabit = false
                },
                onCancel: {
                    showAddHabit = false
                }
            )
        }
    }
    
    private var todayCompletedCount: Int {
        dataStore.habits.filter { habit in
            habit.records.contains { record in
                Calendar.current.isDateInToday(record.date) && record.isCompleted
            }
        }.count
    }
    
    private var currentStreak: Int {
        // 计算所有习惯的最小连续天数
        guard !dataStore.habits.isEmpty else { return 0 }
        
        var minStreak = Int.max
        
        for habit in dataStore.habits {
            var streak = 0
            var date = Date()
            
            while true {
                let hasRecord = habit.records.contains { record in
                    Calendar.current.isDate(record.date, inSameDayAs: date) && record.isCompleted
                }
                
                if hasRecord {
                    streak += 1
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                } else {
                    break
                }
            }
            
            minStreak = min(minStreak, streak)
        }
        
        return minStreak == Int.max ? 0 : minStreak
    }
}

struct HabitRow: View {
    @EnvironmentObject var dataStore: DataStore
    let habit: Habit
    
    var isCompletedToday: Bool {
        habit.records.contains { record in
            Calendar.current.isDateInToday(record.date) && record.isCompleted
        }
    }
    
    var streak: Int {
        var streak = 0
        var date = Date()
        
        while true {
            let hasRecord = habit.records.contains { record in
                Calendar.current.isDate(record.date, inSameDayAs: date) && record.isCompleted
            }
            
            if hasRecord {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        HStack {
            // 习惯图标
            Text(habit.icon)
                .font(.system(size: 32))
                .frame(width: 50)
            
            // 习惯信息
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                HStack {
                    Text(habit.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if streak > 0 {
                        Text("• \(streak)天连续")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // 打卡按钮
            Button(action: {
                if !isCompletedToday {
                    dataStore.toggleHabit(habit)
                }
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isCompletedToday ? .green : .gray)
            }
            .buttonStyle(.plain)
            .disabled(isCompletedToday)
        }
        .padding(.vertical, 8)
    }
}

struct HabitStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 200)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
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
            Text("添加新习惯")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("习惯名称")
                    .font(.headline)
                TextField("输入习惯名称...", text: $name)
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
                    .disabled(name.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

