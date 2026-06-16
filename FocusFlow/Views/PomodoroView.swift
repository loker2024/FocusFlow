import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var pomodoroTimer: PomodoroTimerController

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

                                Button(action: pomodoroTimer.reset) {
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
                                    Picker("专注时长", selection: $pomodoroTimer.selectedDuration) {
                                        ForEach(pomodoroTimer.durations, id: \.self) { duration in
                                            Text("\(duration)分").tag(duration)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .disabled(pomodoroTimer.currentSession != nil)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("今天推进什么")
                                        .font(.subheadline.weight(.semibold))
                                    TextField("例如：整理课程笔记第 2 节", text: $pomodoroTimer.taskName)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(pomodoroTimer.currentSession != nil)
                                }

                                Text(pomodoroTimer.currentSession == nil ? "小步开始，稳定结束。完成的一轮会进入今日统计。" : "这一轮会在后台继续，切换页面不会打断。")
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
}
