import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var timeRemaining: Int = 25 * 60
    @State private var totalTime: Int = 25 * 60
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var currentSession: PomodoroSession?
    @State private var taskName: String = ""
    @State private var selectedDuration: Int = 25
    
    let durations = [15, 25, 30, 45, 60]
    
    var minutes: Int {
        timeRemaining / 60
    }
    
    var seconds: Int {
        timeRemaining % 60
    }
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("番茄钟")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // 时长选择
            HStack {
                Text("时长:")
                    .font(.headline)
                Picker("时长", selection: $selectedDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text("\(duration) 分钟").tag(duration)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .onChange(of: selectedDuration) { _, newValue in
                    if !isRunning {
                        timeRemaining = newValue * 60
                        totalTime = newValue * 60
                    }
                }
            }
            
            // 计时器显示
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isRunning ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                
                // 时间显示
                VStack {
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                    
                    Text(isRunning ? "专注中..." : "准备开始")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // 任务名称
            VStack(alignment: .leading, spacing: 8) {
                Text("任务名称")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("正在做什么...", text: $taskName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .disabled(isRunning)
            }
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 120, height: 50)
                        .background(isRunning ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: resetTimer) {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 120, height: 50)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            // 今日统计
            VStack(alignment: .leading, spacing: 10) {
                Text("今日统计")
                    .font(.headline)
                
                HStack {
                    StatCard(title: "完成番茄", value: "\(todayCompletedCount)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "专注时间", value: "\(todayFocusMinutes)分钟", icon: "clock.fill", color: .blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(40)
    }
    
    private var todayCompletedCount: Int {
        dataStore.pomodoroSessions.filter {
            Calendar.current.isDateInToday($0.startTime) && $0.isCompleted
        }.count
    }
    
    private var todayFocusMinutes: Int {
        dataStore.pomodoroSessions.filter {
            Calendar.current.isDateInToday($0.startTime) && $0.isCompleted
        }.reduce(0) { $0 + $1.duration }
    }
    
    private func startTimer() {
        if currentSession == nil {
            currentSession = PomodoroSession(duration: selectedDuration, taskName: taskName)
        }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    completeSession()
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        pauseTimer()
        timeRemaining = selectedDuration * 60
        totalTime = selectedDuration * 60
        currentSession = nil
    }
    
    private func completeSession() {
        pauseTimer()
        
        if let session = currentSession {
            dataStore.completePomodoroSession(session)
            dataStore.addPomodoroSession(session)
            currentSession = nil
        }
        
        // 播放提示音
        NSSound.beep()
        
        timeRemaining = selectedDuration * 60
        totalTime = selectedDuration * 60
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 150)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
