import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventDate = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var newEventIcon = "📅"
    @State private var newEventColor = "blue"
    @State private var newEventIsRepeat = false
    
    let icons = ["📅", "🎂", "🎄", "🎉", "✈️", "💼", "🎓", "💍", "🏠", "🌟"]
    let colors = ["blue", "red", "green", "purple", "orange", "pink"]
    
    var sortedEvents: [CountdownEvent] {
        dataStore.countdownEvents.sorted { $0.daysRemaining < $1.daysRemaining }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            HStack {
                Text("倒数日")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showAddEvent = true }) {
                    Label("添加事件", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 统计
            HStack {
                CountdownStatCard(
                    title: "即将到来",
                    count: dataStore.countdownEvents.filter { $0.daysRemaining > 0 && $0.daysRemaining <= 7 }.count,
                    icon: "clock.fill",
                    color: .orange
                )
                
                CountdownStatCard(
                    title: "已过期",
                    count: dataStore.countdownEvents.filter { $0.daysRemaining < 0 }.count,
                    icon: "exclamationmark.circle.fill",
                    color: .red
                )
            }
            
            // 事件列表
            List {
                ForEach(sortedEvents) { event in
                    CountdownEventRow(event: event)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        dataStore.deleteCountdownEvent(sortedEvents[index])
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding(40)
        .sheet(isPresented: $showAddEvent) {
            AddCountdownSheet(
                title: $newEventTitle,
                date: $newEventDate,
                icon: $newEventIcon,
                color: $newEventColor,
                isRepeat: $newEventIsRepeat,
                icons: icons,
                colors: colors,
                onSave: {
                    let event = CountdownEvent(
                        title: newEventTitle,
                        date: newEventDate,
                        icon: newEventIcon,
                        color: newEventColor,
                        isRepeatYearly: newEventIsRepeat
                    )
                    dataStore.addCountdownEvent(event)
                    newEventTitle = ""
                    newEventDate = Date().addingTimeInterval(7 * 24 * 3600)
                    newEventIcon = "📅"
                    newEventColor = "blue"
                    newEventIsRepeat = false
                    showAddEvent = false
                },
                onCancel: {
                    showAddEvent = false
                }
            )
        }
    }
}

struct CountdownEventRow: View {
    let event: CountdownEvent
    
    var daysText: String {
        let days = event.daysRemaining
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "明天"
        } else if days > 0 {
            return "\(days)天后"
        } else {
            return "\(-days)天前"
        }
    }
    
    var statusColor: Color {
        let days = event.daysRemaining
        if days < 0 {
            return .red
        } else if days <= 3 {
            return .orange
        } else if days <= 7 {
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack {
            // 图标
            Text(event.icon)
                .font(.system(size: 40))
                .frame(width: 60)
            
            // 事件信息
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if event.isRepeatYearly {
                    Text("每年重复")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // 倒计时
            VStack {
                Text(daysText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                
                if event.daysRemaining > 0 {
                    Text("天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CountdownStatCard: View {
    let title: String
    let count: Int
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
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 150)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AddCountdownSheet: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var icon: String
    @Binding var color: String
    @Binding var isRepeat: Bool
    let icons: [String]
    let colors: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加倒数事件")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("事件名称")
                    .font(.headline)
                TextField("输入事件名称...", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("选择日期")
                    .font(.headline)
                DatePicker("日期", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("选择图标")
                    .font(.headline)
                
                HStack {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { self.icon = icon }) {
                            Text(icon)
                                .font(.system(size: 24))
                                .padding(6)
                                .background(self.icon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("选择颜色")
                    .font(.headline)
                
                HStack {
                    ForEach(colors, id: \.self) { color in
                        Button(action: { self.color = color }) {
                            Circle()
                                .fill(colorFromString(color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(self.color == color ? Color.black : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Toggle("每年重复", isOn: $isRepeat)
                .font(.headline)
            
            HStack {
                Button("取消", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 450)
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .blue
        }
    }
}

