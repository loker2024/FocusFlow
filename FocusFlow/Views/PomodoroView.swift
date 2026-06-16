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
        AppPage(
            title: "专注训练",
            subtitle: "把一天切成可完成的专注块，每一轮都在训练注意力和执行力。",
            icon: "timer"
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 24) {
                        SectionPanel(title: "当前一轮", subtitle: focusPrompt) {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.16), lineWidth: 18)
                                    .frame(width: 236, height: 236)
                                
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        isRunning ? Color.green : Color.accentColor,
                                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                    )
                                    .frame(width: 236, height: 236)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.5), value: progress)
                                
                                VStack(spacing: 8) {
                                    Text(String(format: "%02d:%02d", minutes, seconds))
                                        .font(.system(size: 58, weight: .bold, design: .monospaced))
                                        .minimumScaleFactor(0.8)
                                    
                                    Label(isRunning ? "沉浸中" : "准备开始", systemImage: isRunning ? "bolt.fill" : "sparkle")
                                        .font(.callout.weight(.semibold))
                                        .foregroundColor(isRunning ? .green : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    if isRunning {
                                        pauseTimer()
                                    } else {
                                        startTimer()
                                    }
                                }) {
                                    Label(isRunning ? "暂停" : "开始专注", systemImage: isRunning ? "pause.fill" : "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(isRunning ? Color.orange : Color.green)
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: resetTimer) {
                                    Label("重置", systemImage: "arrow.counterclockwise")
                                        .font(.headline)
                                        .frame(width: 118, height: 46)
                                        .background(Color.secondary.opacity(0.18))
                                        .foregroundColor(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        SectionPanel(title: "本轮设定", subtitle: "开始前只选一件事，降低切换成本。") {
                            VStack(alignment: .leading, spacing: 18) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("专注时长")
                                        .font(.subheadline.weight(.semibold))
                                    Picker("专注时长", selection: $selectedDuration) {
                                        ForEach(durations, id: \.self) { duration in
                                            Text("\(duration)分").tag(duration)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: selectedDuration) { _, newValue in
                                        if !isRunning {
                                            timeRemaining = newValue * 60
                                            totalTime = newValue * 60
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("今天推进什么")
                                        .font(.subheadline.weight(.semibold))
                                    TextField("例如：整理课程笔记第 2 节", text: $taskName)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isRunning)
                                }
                                
                                Text("小步开始，稳定结束。完成的一轮会进入今日统计。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 320)
                    }
                    
                    HStack(spacing: 16) {
                        MetricCard(
                            title: "今日完成",
                            value: "\(todayCompletedCount) 轮",
                            caption: todayCompletedCount == 0 ? "先建立今天的起点" : "每轮都是一次兑现",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        MetricCard(
                            title: "专注沉淀",
                            value: "\(todayFocusMinutes) 分钟",
                            caption: "只统计完整完成的专注块",
                            icon: "clock.fill",
                            color: .blue
                        )
                    }
                }
            }
        }
        .onDisappear {
            pauseTimer()
        }
    }
    
    private var focusPrompt: String {
        if isRunning {
            return "注意力跑开时，把它温和地带回当前这一件事。"
        }
        
        if todayCompletedCount == 0 {
            return "先完成一轮，让今天有一个可靠的起点。"
        }
        
        return "今天已经完成 \(todayCompletedCount) 轮，继续把节奏往前推。"
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
        timer?.invalidate()
        
        if currentSession == nil {
            currentSession = PomodoroSession(
                duration: selectedDuration,
                taskName: taskName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
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
            currentSession = nil
        }
        
        // 播放提示音
        NSSound.beep()
        
        timeRemaining = selectedDuration * 60
        totalTime = selectedDuration * 60
    }
}
