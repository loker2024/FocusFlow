import SwiftUI

struct TimeTrackerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var isTracking = false
    @State private var currentEntry: TimeEntry?
    @State private var selectedCategory = "深度工作"
    @State private var project = ""
    @State private var note = ""
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showHistory = false
    
    let categories = ["深度工作", "学习输入", "阅读沉淀", "训练健康", "恢复休息", "日常事务", "其他"]
    
    var body: some View {
        AppPage(
            title: "时间账本",
            subtitle: "看见时间流向，才能把注意力投给真正会积累的事情。",
            icon: "chart.bar.doc.horizontal",
            actionTitle: "记录历史",
            actionIcon: "clock.arrow.circlepath",
            action: { showHistory.toggle() }
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 24) {
                        SectionPanel(title: "当前投入", subtitle: isTracking ? "这一段时间正在被认真记下。" : "开始前先给时间一个去向。") {
                            VStack(spacing: 14) {
                                Text(timeString(from: elapsedTime))
                                    .font(.system(size: 68, weight: .bold, design: .monospaced))
                                    .foregroundColor(isTracking ? .green : .primary)
                                    .minimumScaleFactor(0.7)
                                
                                Label(isTracking ? "正在记录" : "等待开始", systemImage: isTracking ? "record.circle.fill" : "clock")
                                    .font(.callout.weight(.semibold))
                                    .foregroundColor(isTracking ? .green : .secondary)
                                
                                Button(action: {
                                    if isTracking {
                                        stopTracking()
                                    } else {
                                        startTracking()
                                    }
                                }) {
                                    Label(isTracking ? "结束并入账" : "开始记录", systemImage: isTracking ? "stop.fill" : "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(isTracking ? Color.red : Color.green)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                
                                if !isTracking {
                                    Button(action: resetTracking) {
                                        Label("清空计时", systemImage: "arrow.counterclockwise")
                                            .frame(maxWidth: .infinity, minHeight: 36)
                                    }
                                }
                            }
                        }
                        
                        SectionPanel(title: "记录标签", subtitle: "分类越清楚，复盘时越容易调整节奏。") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("类别")
                                            .font(.subheadline.weight(.semibold))
                                        Picker("类别", selection: $selectedCategory) {
                                            ForEach(categories, id: \.self) { category in
                                                Text(category).tag(category)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("项目")
                                            .font(.subheadline.weight(.semibold))
                                        TextField("例如：FocusFlow 界面打磨", text: $project)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("备注")
                                        .font(.subheadline.weight(.semibold))
                                    TextField("记录投入目标、阻力或下一步", text: $note)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                        .frame(width: 360)
                        .disabled(isTracking)
                        .opacity(isTracking ? 0.62 : 1)
                    }
                    
                    SectionPanel(title: "今日结构", subtitle: "不是每一分钟都要紧绷，但每一段都应该被看见。") {
                        if todayCategories.isEmpty {
                            EmptyStateView(
                                icon: "clock.badge",
                                title: "今天还没有入账",
                                message: "先记录一段真实投入，晚上复盘时就有证据可看。"
                            )
                            .frame(maxWidth: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(todayCategories, id: \.self) { category in
                                        CategoryStatCard(
                                            category: category,
                                            duration: todayDuration(for: category)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .popover(isPresented: $showHistory) {
            TimeHistoryView()
                .frame(width: 420, height: 520)
        }
        .onDisappear {
            if isTracking {
                stopTracking()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private var todayCategories: [String] {
        Set(dataStore.timeEntries
            .filter { Calendar.current.isDateInToday($0.startTime) }
            .map { $0.category }
        ).sorted()
    }
    
    private func todayDuration(for category: String) -> TimeInterval {
        dataStore.timeEntries
            .filter { Calendar.current.isDateInToday($0.startTime) && $0.category == category }
            .reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startTracking() {
        timer?.invalidate()
        
        currentEntry = TimeEntry(
            category: selectedCategory,
            project: project.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        isTracking = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if let entry = currentEntry {
                    elapsedTime = Date().timeIntervalSince(entry.startTime)
                }
            }
        }
    }
    
    private func stopTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
        
        if let entry = currentEntry {
            dataStore.stopTimeEntry(entry)
            currentEntry = nil
        }
        
        // 重置输入
        project = ""
        note = ""
        elapsedTime = 0
    }
    
    private func resetTracking() {
        elapsedTime = 0
        currentEntry = nil
    }
}

struct CategoryStatCard: View {
    let category: String
    let duration: TimeInterval
    
    var body: some View {
        VStack {
            Text(category)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(timeString)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(width: 100)
        .padding()
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.appStroke)
        )
    }
    
    private var timeString: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct TimeHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack {
            Text("时间记录")
                .font(.headline)
                .padding()
            
            List(dataStore.timeEntries.sorted(by: { $0.startTime > $1.startTime })) { entry in
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.category)
                            .font(.headline)
                        Text(entry.project.isEmpty ? "未命名项目" : entry.project)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(entry.startTime, style: .date)
                            .font(.caption)
                        Text(timeString(from: entry.duration))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .padding(.vertical, 4)
            }
            .overlay {
                if dataStore.timeEntries.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "暂无时间记录",
                        message: "停止一次追踪后，记录会出现在这里。"
                    )
                }
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%dh%02dm", hours, minutes)
    }
}
