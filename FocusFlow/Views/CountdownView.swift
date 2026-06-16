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
        dataStore.countdownEvents.sorted { lhs, rhs in
            let lhsDays = lhs.daysRemaining
            let rhsDays = rhs.daysRemaining

            if (lhsDays < 0) != (rhsDays < 0) {
                return lhsDays >= 0
            }

            if lhsDays < 0 {
                return lhsDays > rhsDays
            }

            return lhsDays < rhsDays
        }
    }

    var body: some View {
        AppPage(
            title: "关键日期",
            subtitle: "把截止线、纪念日和阶段节点放在眼前，提前安排而不是临时追赶。",
            icon: "calendar",
            actionTitle: "添加日期",
            actionIcon: "plus",
            action: { showAddEvent = true }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MetricStrip {
                    MetricCard(
                        title: "7 天内",
                        value: "\(upcomingSoonCount) 个",
                        caption: "需要提前进入视野",
                        icon: "clock.fill",
                        color: .orange
                    )

                    MetricCard(
                        title: "已错过",
                        value: "\(expiredCount) 个",
                        caption: expiredCount == 0 ? "节奏保持得不错" : "尽快复盘处理",
                        icon: "exclamationmark.circle.fill",
                        color: .red
                    )

                    MetricCard(
                        title: "全部节点",
                        value: "\(dataStore.countdownEvents.count) 个",
                        caption: "人生进度也需要被看见",
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                }

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
                .appListContainer(minHeight: 380)
                .overlay {
                    if dataStore.countdownEvents.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.plus",
                            title: "还没有关键日期",
                            message: "添加考试、交付、纪念日或阶段节点，让计划提前发生。"
                        )
                    }
                }
            }
        }
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
                    let trimmedTitle = newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else { return }

                    let event = CountdownEvent(
                        title: trimmedTitle,
                        date: newEventDate,
                        icon: newEventIcon,
                        color: newEventColor,
                        isRepeatYearly: newEventIsRepeat
                    )
                    dataStore.addCountdownEvent(event)
                    resetNewEvent()
                    showAddEvent = false
                },
                onCancel: {
                    resetNewEvent()
                    showAddEvent = false
                }
            )
        }
    }

    private func resetNewEvent() {
        newEventTitle = ""
        newEventDate = Date().addingTimeInterval(7 * 24 * 3600)
        newEventIcon = "📅"
        newEventColor = "blue"
        newEventIsRepeat = false
    }

    private var upcomingSoonCount: Int {
        dataStore.countdownEvents.filter { $0.daysRemaining >= 0 && $0.daysRemaining <= 7 }.count
    }

    private var expiredCount: Int {
        dataStore.countdownEvents.filter { $0.daysRemaining < 0 }.count
    }
}

struct CountdownEventRow: View {
    let event: CountdownEvent

    var eventColor: Color {
        Color.appNamed(event.color)
    }

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
        HStack(spacing: 14) {
            Text(event.icon)
                .font(.system(size: 40))
                .frame(width: 58, height: 58)
                .background(eventColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.nextOccurrenceDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if event.isRepeatYearly {
                    PillBadge(text: "每年重复", color: .blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(daysText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)

                if event.daysRemaining > 0 {
                    Text("提前安排")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
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
        FormSheet(title: "添加关键日期", width: 450) {
            VStack(alignment: .leading, spacing: 10) {
                Text("日期名称")
                    .font(.headline)
                TextField("例如：期末复习完成节点", text: $title)
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

                IconChoiceGrid(icons: icons, selection: $icon, columns: 5, iconSize: 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("选择颜色")
                    .font(.headline)

                ColorSwatchPicker(colors: colors, selection: $color)
            }

            Toggle("每年重复", isOn: $isRepeat)
                .font(.headline)

            SheetActions(
                isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}
