import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddEvent = false
    @State private var selectedEvent: CountdownEvent?
    @State private var eventPendingDeletion: CountdownEvent?
    @State private var newEventTitle = ""
    @State private var newEventNote = ""
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
            subtitle: "记录考试、截止日和纪念日，随时看看还剩多少天。",
            icon: "calendar",
            actionTitle: "添加日期",
            actionIcon: "plus",
            action: { showAddEvent = true }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MetricStrip {
                    MetricCard(
                        title: "近 7 天",
                        value: "\(upcomingSoonCount) 个",
                        caption: "最近要留意",
                        icon: "clock.fill",
                        color: .orange
                    )

                    MetricCard(
                        title: "已过日期",
                        value: "\(expiredCount) 个",
                        caption: expiredCount == 0 ? "目前没有" : "可以删除或重新安排",
                        icon: "exclamationmark.circle.fill",
                        color: .red
                    )

                    MetricCard(
                        title: "已记录",
                        value: "\(dataStore.countdownEvents.count) 个",
                        caption: "考试、纪念日等",
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                }

                List {
                    ForEach(sortedEvents) { event in
                        CountdownEventRow(
                            event: event,
                            onOpen: { selectedEvent = event },
                            onDelete: { eventPendingDeletion = event }
                        )
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            eventPendingDeletion = sortedEvents[index]
                        }
                    }
                }
                .appListContainer(minHeight: 380)
                .overlay {
                    if dataStore.countdownEvents.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.plus",
                            title: "还没有日期",
                            message: "先添加一个考试、截止日或纪念日。"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddCountdownSheet(
                title: $newEventTitle,
                note: $newEventNote,
                date: $newEventDate,
                icon: $newEventIcon,
                color: $newEventColor,
                isRepeat: $newEventIsRepeat,
                icons: icons,
                colors: colors,
                onSave: {
                    let trimmedTitle = newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedNote = newEventNote.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else { return }

                    let event = CountdownEvent(
                        title: trimmedTitle,
                        date: newEventDate,
                        icon: newEventIcon,
                        color: newEventColor,
                        isRepeatYearly: newEventIsRepeat,
                        note: trimmedNote
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
        .popover(item: $selectedEvent) { event in
            CountdownEventDetailPopover(event: event)
                .frame(width: 390)
        }
        .alert("删除日期？", isPresented: deleteConfirmationBinding, presenting: eventPendingDeletion) { event in
            Button("取消", role: .cancel) {
                eventPendingDeletion = nil
            }
            Button("删除", role: .destructive) {
                dataStore.deleteCountdownEvent(event)
                eventPendingDeletion = nil
            }
        } message: { event in
            Text("删除“\(event.title)”？删除后无法恢复。")
        }
    }

    private func resetNewEvent() {
        newEventTitle = ""
        newEventNote = ""
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

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { eventPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    eventPendingDeletion = nil
                }
            }
        )
    }
}

struct CountdownEventRow: View {
    let event: CountdownEvent
    let onOpen: () -> Void
    let onDelete: () -> Void

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
            return "还有 \(days) 天"
        } else {
            return "已过 \(-days) 天"
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
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    Text(event.icon)
                        .font(.system(size: 40))
                        .frame(width: 58, height: 58)
                        .background(eventColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(event.nextOccurrenceDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let note = event.trimmedNote {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        if event.isRepeatYearly {
                            PillBadge(text: "每年", color: .blue)
                        }
                    }

                    Spacer()

                    Text(daysText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("查看日期详情")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("删除日期")
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("删除日期", role: .destructive, action: onDelete)
        }
    }
}

struct CountdownEventDetailPopover: View {
    let event: CountdownEvent

    private var eventColor: Color {
        Color.appNamed(event.color)
    }

    private var daysText: String {
        let days = event.daysRemaining
        if days == 0 {
            return "就是今天"
        } else if days == 1 {
            return "还有 1 天"
        } else if days > 0 {
            return "还有 \(days) 天"
        } else {
            return "已经过去 \(-days) 天"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Text(event.icon)
                    .font(.system(size: 36))
                    .frame(width: 54, height: 54)
                    .background(eventColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title2.weight(.bold))

                    Text(daysText)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(eventColor)
                }

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                detailRow(
                    title: "日期",
                    value: event.nextOccurrenceDate.formatted(
                        .dateTime.year().month(.wide).day().weekday(.wide)
                    ),
                    icon: "calendar"
                )

                detailRow(
                    title: "重复",
                    value: event.isRepeatYearly ? "每年重复" : "不重复",
                    icon: event.isRepeatYearly ? "repeat" : "calendar.badge.minus"
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("备注")
                    .font(.headline)

                if let note = event.trimmedNote {
                    ScrollView {
                        Text(note)
                            .font(.callout)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 180)
                } else {
                    Text("没有备注")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.appStroke)
            )
        }
        .padding(22)
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}

struct AddCountdownSheet: View {
    @Binding var title: String
    @Binding var note: String
    @Binding var date: Date
    @Binding var icon: String
    @Binding var color: String
    @Binding var isRepeat: Bool
    let icons: [String]
    let colors: [String]
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        FormSheet(title: "添加日期", width: 450) {
            VStack(alignment: .leading, spacing: 10) {
                Text("名称")
                    .font(.headline)
                TextField("例如：期末考试", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("备注")
                    .font(.headline)
                PromptTextEditor(
                    text: $note,
                    prompt: "写下地点、准备事项或其他需要记住的内容（可选）",
                    minHeight: 82
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("日期")
                    .font(.headline)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("图标")
                    .font(.headline)

                IconChoiceGrid(icons: icons, selection: $icon, columns: 5, iconSize: 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("颜色")
                    .font(.headline)

                ColorSwatchPicker(colors: colors, selection: $color)
            }

            Toggle("每年重复", isOn: $isRepeat)
                .font(.headline)

            SheetActions(
                saveTitle: "添加",
                isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}

private extension CountdownEvent {
    var trimmedNote: String? {
        guard let note else { return nil }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
