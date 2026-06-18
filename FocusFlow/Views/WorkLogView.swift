import Charts
import SwiftUI

struct WorkLogView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var logContent = ""
    @State private var selectedMood = "😊"
    @State private var productivity = 3
    @State private var showHistory = false
    @State private var selectedDate = Date()

    let moods = ["😊", "😐", "😔", "😤", "😴", "🎉", "💪", "🤔"]

    var body: some View {
        AppPage(
            title: "每日复盘",
            subtitle: "把今天的投入、阻力和收获写下来，让成长留下可回看的证据。",
            icon: "book.closed",
            actionTitle: "复盘历史",
            actionIcon: "calendar",
            action: { showHistory.toggle() }
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 18) {
                        SectionPanel(title: "复盘日期", subtitle: "可以补记，也可以回看某一天。") {
                            HStack {
                                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)

                                Spacer()

                                Text(selectedDate, style: .date)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        SectionPanel(title: "状态标记", subtitle: "记录状态，不评判自己。") {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    ForEach(moods, id: \.self) { mood in
                                        Button(action: { selectedMood = mood }) {
                                            Text(mood)
                                                .font(.system(size: 27))
                                                .frame(width: 40, height: 40)
                                                .background(selectedMood == mood ? Color.appMutedAccent : Color.clear)
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Button(action: { productivity = rating }) {
                                            Image(systemName: rating <= productivity ? "star.fill" : "star")
                                                .font(.title2)
                                                .foregroundColor(.yellow)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Text(productivityLabel)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 6)
                                }
                            }
                        }
                    }

                    FocusReviewChart(
                        date: selectedDate,
                        sessions: dataStore.completedPomodoroSessions(on: selectedDate),
                        tasks: dataStore.tasks
                    )

                    SectionPanel(title: "今日沉淀", subtitle: "建议写下：完成了什么、卡在哪里、明天先做哪一步。") {
                        PromptTextEditor(
                            text: $logContent,
                            prompt: "今天我推进了……\n遇到的阻力是……\n明天最先启动的一步是……",
                            minHeight: 220
                        )
                    }

                    HStack {
                        Text("复盘不需要完美，真实比漂亮更有用。")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: saveLog) {
                            Label("保存复盘", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(width: 148, height: 46)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(logContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .popover(isPresented: $showHistory) {
            WorkLogHistoryView()
                .frame(width: 520, height: 620)
        }
        .onAppear(perform: loadSelectedDateLog)
        .onChange(of: selectedDate) { _, _ in
            loadSelectedDateLog()
        }
    }

    private var productivityLabel: String {
        switch productivity {
        case 1: return "低电量，先恢复"
        case 2: return "有阻力，少量推进"
        case 3: return "稳定完成"
        case 4: return "状态不错"
        default: return "高质量投入"
        }
    }

    private func saveLog() {
        let trimmedContent = logContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let log = WorkLog(
            date: selectedDate,
            content: trimmedContent,
            mood: selectedMood,
            productivity: productivity
        )
        dataStore.addWorkLog(log)

        // 显示提示
        NSSound.beep()
    }

    private func loadSelectedDateLog() {
        if let log = dataStore.workLog(for: selectedDate) {
            logContent = log.content
            selectedMood = log.mood
            productivity = log.productivity
        } else {
            logContent = ""
            selectedMood = "😊"
            productivity = 3
        }
    }
}

private struct FocusReviewSlice: Identifiable {
    let id: String
    let title: String
    let seconds: Int
}

private struct FocusReviewChart: View {
    let date: Date
    let sessions: [PomodoroSession]
    let tasks: [TaskItem]

    private let palette: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .teal,
        .indigo,
        .cyan
    ]

    var body: some View {
        SectionPanel(
            title: "当日专注分布",
            subtitle: "按关联待办汇总当前复盘日期的完整专注记录。"
        ) {
            if slices.isEmpty {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "这一天还没有专注记录",
                    message: "完成一次专注后，这里会显示时间投入的分布。"
                )
                .frame(maxWidth: .infinity, minHeight: 210)
            } else {
                HStack(spacing: 28) {
                    Chart(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        SectorMark(
                            angle: .value("专注秒数", slice.seconds),
                            innerRadius: .ratio(0.56),
                            angularInset: 1.5
                        )
                        .foregroundStyle(color(for: index).gradient)
                        .cornerRadius(4)
                    }
                    .chartBackground { proxy in
                        GeometryReader { geometry in
                            if let frame = proxy.plotFrame {
                                let plotFrame = geometry[frame]
                                VStack(spacing: 3) {
                                    Text(totalDurationText)
                                        .font(.title2.weight(.bold))
                                    Text("专注总时长")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .position(x: plotFrame.midX, y: plotFrame.midY)
                            }
                        }
                    }
                    .frame(width: 240, height: 220)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(date, format: .dateTime.year().month().day())
                                .font(.headline)

                            Spacer()

                            PillBadge(
                                text: "\(sessions.count) 次专注",
                                color: .blue
                            )
                        }

                        Divider()

                        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                            HStack(spacing: 9) {
                                Circle()
                                    .fill(color(for: index))
                                    .frame(width: 9, height: 9)

                                Text(slice.title)
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Spacer()

                                Text(durationText(seconds: slice.seconds))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var slices: [FocusReviewSlice] {
        var totals: [String: (title: String, seconds: Int)] = [:]

        for session in sessions {
            let key: String
            let title: String

            if let taskID = session.taskID {
                key = "task-\(taskID.uuidString)"
                title = tasks.first { $0.id == taskID }?.title
                    ?? nonEmpty(session.taskName)
                    ?? "已删除待办"
            } else if let sessionName = nonEmpty(session.taskName) {
                key = "name-\(sessionName)"
                title = sessionName
            } else {
                key = "unlinked"
                title = "未关联待办"
            }

            let current = totals[key]?.seconds ?? 0
            totals[key] = (title, current + session.effectiveDurationSeconds)
        }

        return totals.map { key, value in
            FocusReviewSlice(id: key, title: value.title, seconds: value.seconds)
        }
        .sorted { lhs, rhs in
            if lhs.seconds == rhs.seconds {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhs.seconds > rhs.seconds
        }
    }

    private var totalDurationText: String {
        durationText(seconds: sessions.reduce(0) { $0 + $1.effectiveDurationSeconds })
    }

    private func color(for index: Int) -> Color {
        palette[index % palette.count]
    }

    private func durationText(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) 秒"
        }

        let minutes = Int(ceil(Double(seconds) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 {
            return remainder == 0 ? "\(hours) 小时" : "\(hours)小时\(remainder)分"
        }

        return "\(minutes) 分钟"
    }

    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct WorkLogHistoryView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack {
            Text("复盘历史")
                .font(.headline)
                .padding()

            List(dataStore.workLogs.sorted(by: { $0.date > $1.date })) { log in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(log.date, style: .date)
                            .font(.headline)

                        Spacer()

                        Text(log.mood)
                            .font(.title)

                        HStack {
                            ForEach(1...5, id: \.self) { rating in
                                Image(systemName: rating <= log.productivity ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }

                    Text(log.content)
                        .font(.body)
                        .lineLimit(5)
                }
                .padding(.vertical, 8)
            }
            .appListContainer(minHeight: 520)
            .overlay {
                if dataStore.workLogs.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "暂无复盘",
                        message: "保存一次每日复盘后，成长痕迹会显示在这里。"
                    )
                }
            }
        }
    }
}
