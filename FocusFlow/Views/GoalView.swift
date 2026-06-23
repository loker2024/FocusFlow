import SwiftUI

struct GoalView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddGoal = false
    @State private var newGoalTitle = ""
    @State private var newGoalDescription = ""
    @State private var newGoalTargetDate = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var goalPendingDeletion: Goal?

    var body: some View {
        AppPage(
            title: "长期目标",
            subtitle: "把愿望拆成里程碑，用持续推进代替偶尔热血。",
            icon: "target",
            actionTitle: "建立目标",
            actionIcon: "plus",
            action: { showAddGoal = true }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                MetricStrip {
                    MetricCard(
                        title: "进行中",
                        value: "\(activeGoalCount) 个",
                        caption: "保持目标池不过载",
                        icon: "target",
                        color: .blue
                    )

                    MetricCard(
                        title: "已完成",
                        value: "\(completedGoalCount) 个",
                        caption: "每个完成都会改变自我预期",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    MetricCard(
                        title: "里程碑",
                        value: "\(completedMilestoneCount)/\(milestoneCount)",
                        caption: "用节点承接长期进度",
                        icon: "flag.checkered",
                        color: .orange
                    )
                }

                List {
                    ForEach(dataStore.goals) { goal in
                        GoalRow(goal: goal)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            goalPendingDeletion = dataStore.goals[index]
                        }
                    }
                }
                .appListContainer(minHeight: 380)
                .overlay {
                    if dataStore.goals.isEmpty {
                        EmptyStateView(
                            icon: "target",
                            title: "还没有长期目标",
                            message: "先写下一个值得持续 30 天的目标，再拆出第一个里程碑。"
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(
                title: $newGoalTitle,
                description: $newGoalDescription,
                targetDate: $newGoalTargetDate,
                onSave: {
                    let trimmedTitle = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedDescription = newGoalDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else { return }

                    let goal = Goal(
                        title: trimmedTitle,
                        description: trimmedDescription,
                        targetDate: newGoalTargetDate
                    )
                    dataStore.addGoal(goal)
                    resetNewGoal()
                    showAddGoal = false
                },
                onCancel: {
                    resetNewGoal()
                    showAddGoal = false
                }
            )
        }
        .alert("删除长期目标？", isPresented: deleteConfirmationBinding, presenting: goalPendingDeletion) { goal in
            Button("取消", role: .cancel) {
                goalPendingDeletion = nil
            }
            Button("删除", role: .destructive) {
                dataStore.deleteGoal(goal)
                goalPendingDeletion = nil
            }
        } message: { goal in
            Text("“\(goal.title)”和其中的里程碑会一起删除，删除后无法恢复。")
        }
    }

    private func resetNewGoal() {
        newGoalTitle = ""
        newGoalDescription = ""
        newGoalTargetDate = Date().addingTimeInterval(30 * 24 * 3600)
    }

    private var activeGoalCount: Int {
        dataStore.goals.filter { $0.progress < 100 }.count
    }

    private var completedGoalCount: Int {
        dataStore.goals.filter { $0.progress >= 100 }.count
    }

    private var milestoneCount: Int {
        dataStore.goals.reduce(0) { $0 + $1.milestones.count }
    }

    private var completedMilestoneCount: Int {
        dataStore.goals.reduce(0) { total, goal in
            total + goal.milestones.filter(\.isCompleted).count
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { goalPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    goalPendingDeletion = nil
                }
            }
        )
    }
}

struct GoalRow: View {
    @EnvironmentObject var dataStore: DataStore
    let goal: Goal
    @State private var showDetail = false

    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: goal.targetDate)
        ).day ?? 0
    }

    var daysText: String {
        if goal.progress >= 100 {
            return "已完成"
        }

        if daysRemaining < 0 {
            return "逾期 \(-daysRemaining) 天"
        }

        if daysRemaining == 0 {
            return "今天到期"
        }

        return "剩余 \(daysRemaining) 天"
    }

    var badgeColor: Color {
        if goal.progress >= 100 {
            return .green
        }

        if daysRemaining < 0 {
            return .red
        }

        return daysRemaining <= 7 ? .orange : .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)

                    if !goal.goalDescription.isEmpty {
                        Text(goal.goalDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    PillBadge(
                        text: daysText,
                        color: badgeColor
                    )

                    Text(goal.targetDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("推进进度")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(goal.progress))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }

                ProgressView(value: goal.progress / 100)
                    .progressViewStyle(.linear)
                    .tint(goal.progress >= 100 ? .green : .blue)

                Slider(
                    value: Binding(
                        get: { goal.progress },
                        set: { dataStore.updateGoalProgress(goal, progress: $0) }
                    ),
                    in: 0...100,
                    step: 5
                )
            }

            if !goal.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("里程碑")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(goal.milestones) { milestone in
                        HStack {
                            Button(action: {
                                dataStore.toggleMilestone(milestone, in: goal)
                            }) {
                                Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(milestone.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)

                            Text(milestone.title)
                                .font(.subheadline)
                                .strikethrough(milestone.isCompleted)
                        }
                    }
                }
            }

            Button(action: { showDetail = true }) {
                Label("补一个里程碑", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDetail) {
                AddMilestoneView(goal: goal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddMilestoneView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    @State private var milestoneTitle = ""

    var body: some View {
        FormSheet(title: "添加里程碑", width: 300) {
            TextField("例如：完成第一版方案", text: $milestoneTitle)
                .textFieldStyle(.roundedBorder)

            SheetActions(
                saveTitle: "添加",
                isSaveDisabled: milestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: {
                    milestoneTitle = ""
                    dismiss()
                },
                onSave: {
                    let trimmedTitle = milestoneTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedTitle.isEmpty {
                        let milestone = Milestone(title: trimmedTitle)
                        dataStore.addMilestone(to: goal, milestone: milestone)
                        milestoneTitle = ""
                        dismiss()
                    }
                }
            )
        }
    }
}

struct AddGoalSheet: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var targetDate: Date
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        FormSheet(title: "建立长期目标") {
            VStack(alignment: .leading, spacing: 10) {
                Text("目标标题")
                    .font(.headline)
                TextField("例如：30 天完成 SwiftUI 作品集", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("为什么值得坚持")
                    .font(.headline)
                PromptTextEditor(
                    text: $description,
                    prompt: "写下目标背后的价值、验收标准和最小推进方式。",
                    minHeight: 110
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("目标日期")
                    .font(.headline)
                DatePicker("目标日期", selection: $targetDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            SheetActions(
                isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}
