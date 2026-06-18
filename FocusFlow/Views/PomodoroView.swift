import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var pomodoroTimer: PomodoroTimerController

    var body: some View {
        AppPage(
            title: "专注训练",
            subtitle: "选择一个待办进入专注，把注意力留给当前最重要的一步。",
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
                                    .trim(from: 0, to: pomodoroTimer.progress)
                                    .stroke(
                                        pomodoroTimer.isRunning ? Color.green : Color.accentColor,
                                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                    )
                                    .frame(width: 236, height: 236)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.5), value: pomodoroTimer.progress)

                                VStack(spacing: 8) {
                                    Text(String(format: "%02d:%02d", pomodoroTimer.minutes, pomodoroTimer.seconds))
                                        .font(.system(size: 58, weight: .bold, design: .monospaced))
                                        .minimumScaleFactor(0.8)

                                    Label(pomodoroTimer.statusText, systemImage: pomodoroTimer.isRunning ? "bolt.fill" : "sparkle")
                                        .font(.callout.weight(.semibold))
                                        .foregroundColor(pomodoroTimer.isRunning ? .green : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            HStack(spacing: 12) {
                                FilledActionButton(
                                    title: pomodoroTimer.isRunning ? "暂停" : (pomodoroTimer.isPaused ? "继续专注" : "开始专注"),
                                    systemImage: pomodoroTimer.isRunning ? "pause.fill" : "play.fill",
                                    color: pomodoroTimer.isRunning ? .orange : .green,
                                    action: {
                                    if pomodoroTimer.isRunning {
                                        pomodoroTimer.pause()
                                    } else {
                                        pomodoroTimer.start()
                                    }
                                })

                                Button(action: secondaryTimerAction) {
                                    Label(
                                        pomodoroTimer.currentSession == nil ? "重置" : "结束",
                                        systemImage: pomodoroTimer.currentSession == nil ? "arrow.counterclockwise" : "stop.fill"
                                    )
                                        .font(.headline)
                                        .frame(width: 118, height: 46)
                                        .background(
                                            pomodoroTimer.currentSession == nil
                                                ? Color.secondary.opacity(0.18)
                                                : Color.red.opacity(0.14)
                                        )
                                        .foregroundColor(pomodoroTimer.currentSession == nil ? .primary : .red)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SectionPanel {
                            VStack(alignment: .leading, spacing: 18) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("计时方式")
                                        .font(.subheadline.weight(.semibold))

                                    Picker("", selection: $pomodoroTimer.direction) {
                                        ForEach(FocusTimerDirection.allCases, id: \.self) { direction in
                                            Text(direction.rawValue).tag(direction)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.segmented)
                                    .disabled(pomodoroTimer.currentSession != nil)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("关联待办")
                                        .font(.subheadline.weight(.semibold))
                                    Picker("", selection: selectedTaskBinding) {
                                        Text("不关联待办").tag(nil as UUID?)
                                        ForEach(focusableTasks) { task in
                                            Text(task.title).tag(Optional(task.id))
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .disabled(pomodoroTimer.currentSession != nil)
                                }

                                if pomodoroTimer.direction == .countDown {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("专注时长")
                                            .font(.subheadline.weight(.semibold))

                                        LazyVGrid(
                                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                                            spacing: 8
                                        ) {
                                            ForEach(pomodoroTimer.durations, id: \.self) { duration in
                                                Button("\(duration) 分") {
                                                    pomodoroTimer.selectedDuration = duration
                                                }
                                                .buttonStyle(.plain)
                                                .frame(maxWidth: .infinity, minHeight: 34)
                                                .background(
                                                    pomodoroTimer.selectedDuration == duration
                                                        ? Color.accentColor
                                                        : Color.secondary.opacity(0.12)
                                                )
                                                .foregroundColor(
                                                    pomodoroTimer.selectedDuration == duration
                                                        ? .white
                                                        : .primary
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            }
                                        }

                                        HStack {
                                            Text("自定义")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            TextField(
                                                "",
                                                value: $pomodoroTimer.selectedDuration,
                                                format: .number
                                            )
                                            .labelsHidden()
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 76)

                                            Text("分钟")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            Spacer()
                                        }
                                    }
                                    .disabled(pomodoroTimer.currentSession != nil)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("本轮说明")
                                        .font(.subheadline.weight(.semibold))
                                    TextField("例如：整理课程笔记第 2 节", text: $pomodoroTimer.taskName)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(pomodoroTimer.currentSession != nil)
                                }

                                Text(timerHint)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 320)
                    }

                    MetricStrip {
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
    }

    private var focusPrompt: String {
        if pomodoroTimer.isRunning {
            return "注意力跑开时，把它温和地带回当前这一件事。"
        }

        if pomodoroTimer.isPaused {
            return "这一轮已暂停，准备好时可以继续。"
        }

        if todayCompletedCount == 0 {
            return "先完成一轮，让今天有一个可靠的起点。"
        }

        return "今天已经完成 \(todayCompletedCount) 轮，继续把节奏往前推。"
    }

    private var timerHint: String {
        if pomodoroTimer.currentSession != nil {
            return "这一轮会在后台继续，切换页面不会打断。"
        }

        if pomodoroTimer.direction == .countUp {
            return "正向计时从 00:00 开始，结束时会按实际时长保存。"
        }

        return "反向计时结束后会自动保存，也可以提前结束。"
    }

    private func secondaryTimerAction() {
        if pomodoroTimer.currentSession == nil {
            pomodoroTimer.reset()
        } else {
            pomodoroTimer.complete()
        }
    }

    private var todayCompletedCount: Int {
        dataStore.pomodoroSessions.filter {
            Calendar.current.isDateInToday($0.startTime) && $0.isCompleted
        }.count
    }

    private var todayFocusMinutes: Int {
        let seconds = dataStore.pomodoroSessions.filter {
            Calendar.current.isDateInToday($0.startTime) && $0.isCompleted
        }.reduce(0) { $0 + $1.effectiveDurationSeconds }
        return Int(ceil(Double(seconds) / 60))
    }

    private var focusableTasks: [TaskItem] {
        dataStore.tasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var selectedTaskBinding: Binding<UUID?> {
        Binding(
            get: { pomodoroTimer.selectedTaskID },
            set: { taskID in
                let task = dataStore.tasks.first { $0.id == taskID }
                pomodoroTimer.selectTask(task)
            }
        )
    }
}
