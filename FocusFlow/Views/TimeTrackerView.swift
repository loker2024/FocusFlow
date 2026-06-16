import SwiftUI

struct TimeTrackerView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var timeTracker: TimeTrackerController
    @State private var showHistory = false

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
                        SectionPanel(title: "当前投入", subtitle: timeTracker.isTracking ? "这一段时间会在后台继续记录。" : "开始前先给时间一个去向。") {
                            VStack(spacing: 14) {
                                Text(timeString(from: timeTracker.elapsedTime))
                                    .font(.system(size: 68, weight: .bold, design: .monospaced))
                                    .foregroundColor(timeTracker.isTracking ? .green : .primary)
                                    .minimumScaleFactor(0.7)

                                Label(timeTracker.statusText, systemImage: timeTracker.isTracking ? "record.circle.fill" : "clock")
                                    .font(.callout.weight(.semibold))
                                    .foregroundColor(timeTracker.isTracking ? .green : .secondary)

                                FilledActionButton(
                                    title: timeTracker.isTracking ? "结束并入账" : "开始记录",
                                    systemImage: timeTracker.isTracking ? "stop.fill" : "play.fill",
                                    color: timeTracker.isTracking ? .red : .green,
                                    action: {
                                    if timeTracker.isTracking {
                                        timeTracker.stop()
                                    } else {
                                        timeTracker.start()
                                    }
                                })

                                if !timeTracker.isTracking {
                                    Button(action: timeTracker.reset) {
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
                                        Picker("类别", selection: $timeTracker.selectedCategory) {
                                            ForEach(timeTracker.categories, id: \.self) { category in
                                                Text(category).tag(category)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("项目")
                                            .font(.subheadline.weight(.semibold))
                                        TextField("例如：FocusFlow 界面打磨", text: $timeTracker.project)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("备注")
                                        .font(.subheadline.weight(.semibold))
                                    TextField("记录投入目标、阻力或下一步", text: $timeTracker.note)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                        .frame(width: 360)
                        .disabled(timeTracker.isTracking)
                        .opacity(timeTracker.isTracking ? 0.62 : 1)
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
            .reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? Date().timeIntervalSince($1.startTime)) }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
            .appListContainer(minHeight: 430)
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
