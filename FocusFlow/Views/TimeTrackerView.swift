import SwiftUI

struct TimeTrackerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var isTracking = false
    @State private var currentEntry: TimeEntry?
    @State private var selectedCategory = "工作"
    @State private var project = ""
    @State private var note = ""
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showHistory = false
    
    let categories = ["工作", "学习", "运动", "阅读", "娱乐", "休息", "其他"]
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            HStack {
                Text("时间追踪")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showHistory.toggle() }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                }
                .popover(isPresented: $showHistory) {
                    TimeHistoryView()
                        .frame(width: 400, height: 500)
                }
            }
            
            // 计时器显示
            VStack {
                Text(timeString(from: elapsedTime))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(isTracking ? .green : .primary)
                
                Text(isTracking ? "追踪中..." : "准备开始")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // 输入区域
            VStack(spacing: 15) {
                HStack {
                    Text("类别:")
                        .frame(width: 60, alignment: .trailing)
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    
                    Text("项目:")
                        .frame(width: 60, alignment: .trailing)
                    TextField("项目名称", text: $project)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                
                HStack {
                    Text("备注:")
                        .frame(width: 60, alignment: .trailing)
                    TextField("添加备注...", text: $note)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(action: {
                    if isTracking {
                        stopTracking()
                    } else {
                        startTracking()
                    }
                }) {
                    Label(isTracking ? "停止" : "开始", systemImage: isTracking ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 150, height: 50)
                        .background(isTracking ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if !isTracking {
                    Button(action: resetTracking) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .font(.title2)
                            .frame(width: 120, height: 50)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            // 今日统计
            VStack(alignment: .leading, spacing: 10) {
                Text("今日统计")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(todayCategories, id: \.self) { category in
                            CategoryStatCard(
                                category: category,
                                duration: todayDuration(for: category)
                            )
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(40)
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
        currentEntry = TimeEntry(category: selectedCategory, project: project, note: note)
        isTracking = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTracking() {
        isTracking = false
        timer?.invalidate()
        
        if let entry = currentEntry {
            dataStore.stopTimeEntry(entry)
            dataStore.addTimeEntry(entry)
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
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
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
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%dh%02dm", hours, minutes)
    }
}

