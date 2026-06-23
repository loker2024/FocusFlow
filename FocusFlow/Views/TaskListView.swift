import SwiftUI

private enum TaskGroupFilter: Hashable {
    case all
    case ungrouped
    case group(UUID)
}

struct TaskListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject private var pomodoroTimer: PomodoroTimerController
    @State private var showAddTask = false
    @State private var showAddGroup = false
    @State private var selectedTask: TaskItem?
    @State private var taskPendingDeletion: TaskItem?
    @State private var selectedGroup: TaskGroupFilter = .all
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskPriority: TaskItem.Priority = .medium
    @State private var newTaskGroupID: UUID?
    @State private var newGroupName = ""
    @State private var searchText = ""
    @State private var filterStatus: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "全部"
        case pending = "待办"
        case completed = "已完成"
    }

    var body: some View {
        AppPage(
            title: "待办",
            subtitle: "用待办组整理不同方向，把每一项待办变成可以直接进入专注的一步。",
            icon: "checklist",
            actionTitle: "新建待办",
            actionIcon: "plus",
            action: {
                newTaskGroupID = selectedGroup.groupID
                showAddTask = true
            }
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    SearchField(text: $searchText)

                    Picker("状态", selection: $filterStatus) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                }

                MetricStrip {
                    MetricCard(
                        title: "待处理",
                        value: "\(pendingCount) 项",
                        caption: "把下一步写清楚",
                        icon: "circle",
                        color: .orange
                    )
                    MetricCard(
                        title: "今日完成",
                        value: "\(todayCompletedCount) 项",
                        caption: "今天已经兑现的动作",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    MetricCard(
                        title: "待办组",
                        value: "\(dataStore.taskGroups.count) 个",
                        caption: "按方向整理待办",
                        icon: "folder.fill",
                        color: .blue
                    )
                }

                HStack(alignment: .top, spacing: 16) {
                    taskGroupSidebar
                        .frame(width: 220)

                    List {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task) {
                                selectedTask = task
                            } onDelete: {
                                taskPendingDeletion = task
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                taskPendingDeletion = filteredTasks[index]
                            }
                        }
                    }
                    .appListContainer(minHeight: 360)
                    .overlay {
                        if filteredTasks.isEmpty {
                            EmptyStateView(
                                icon: emptyStateIcon,
                                title: emptyStateTitle,
                                message: emptyStateMessage
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(
                title: $newTaskTitle,
                description: $newTaskDescription,
                priority: $newTaskPriority,
                groupID: $newTaskGroupID,
                groups: dataStore.taskGroups,
                onSave: saveTask,
                onCancel: {
                    resetNewTask()
                    showAddTask = false
                }
            )
        }
        .sheet(isPresented: $showAddGroup) {
            AddTaskGroupSheet(
                name: $newGroupName,
                onSave: saveGroup,
                onCancel: {
                    newGroupName = ""
                    showAddGroup = false
                }
            )
        }
        .popover(item: $selectedTask) { task in
            TaskDetailPopover(taskID: task.id)
                .frame(width: 440)
        }
        .alert("删除待办？", isPresented: deleteConfirmationBinding, presenting: taskPendingDeletion) { task in
            Button("取消", role: .cancel) {
                taskPendingDeletion = nil
            }
            Button("删除", role: .destructive) {
                deleteTask(task)
            }
        } message: { task in
            Text("“\(task.title)”会从待办中删除，已有专注记录仍会保留。")
        }
    }

    private var taskGroupSidebar: some View {
        SectionPanel(title: "待办组", subtitle: "选择一个分类查看待办") {
            VStack(spacing: 6) {
                taskGroupButton(
                    title: "全部待办",
                    icon: "tray.full",
                    count: dataStore.tasks.count,
                    filter: .all
                )

                taskGroupButton(
                    title: "未分组",
                    icon: "tray",
                    count: dataStore.tasks.filter { $0.groupID == nil }.count,
                    filter: .ungrouped
                )

                Divider()
                    .padding(.vertical, 4)

                ForEach(dataStore.taskGroups) { group in
                    taskGroupButton(
                        title: group.name,
                        icon: "folder",
                        count: dataStore.tasks.filter { $0.groupID == group.id }.count,
                        filter: .group(group.id),
                        group: group
                    )
                }

                Button(action: { showAddGroup = true }) {
                    Label("新建待办组", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
    }

    private func taskGroupButton(
        title: String,
        icon: String,
        count: Int,
        filter: TaskGroupFilter,
        group: TaskGroup? = nil
    ) -> some View {
        Button(action: { selectedGroup = filter }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(title)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(selectedGroup == filter ? Color.appMutedAccent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let group {
                Button("删除待办组", role: .destructive) {
                    if selectedGroup == .group(group.id) {
                        selectedGroup = .all
                    }
                    dataStore.deleteTaskGroup(group)
                }
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        var tasks = dataStore.tasks

        switch selectedGroup {
        case .all:
            break
        case .ungrouped:
            tasks = tasks.filter { $0.groupID == nil }
        case .group(let groupID):
            tasks = tasks.filter { $0.groupID == groupID }
        }

        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.taskDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch filterStatus {
        case .all:
            break
        case .pending:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter(\.isCompleted)
        }

        return tasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func saveTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        dataStore.addTask(
            TaskItem(
                title: trimmedTitle,
                description: trimmedDescription,
                priority: newTaskPriority,
                groupID: newTaskGroupID
            )
        )
        resetNewTask()
        showAddTask = false
    }

    private func saveGroup() {
        let trimmedName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let group = TaskGroup(name: trimmedName)
        dataStore.addTaskGroup(group)
        selectedGroup = .group(group.id)
        newTaskGroupID = group.id
        newGroupName = ""
        showAddGroup = false
    }

    private func resetNewTask() {
        newTaskTitle = ""
        newTaskDescription = ""
        newTaskPriority = .medium
        newTaskGroupID = selectedGroup.groupID
    }

    private var pendingCount: Int {
        dataStore.tasks.filter { !$0.isCompleted }.count
    }

    private var todayCompletedCount: Int {
        dataStore.tasks.filter {
            $0.isCompleted &&
            $0.completedAt.map(Calendar.current.isDateInToday) == true
        }.count
    }

    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }

        return filterStatus == .completed ? "checkmark.circle" : "checklist"
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "没有匹配结果"
        }

        switch filterStatus {
        case .all:
            return selectedGroup == .all ? "这里还没有待办" : "这个分组还没有待办"
        case .pending:
            return "当前没有待处理事项"
        case .completed:
            return "这里还没有已完成事项"
        }
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "换个关键词或筛选条件再试试。"
        }

        switch filterStatus {
        case .all:
            return "新建一个能直接开始的待办，之后可以把专注记录关联到它。"
        case .pending:
            return "可以切换到“已完成”回看进展，或新建下一步。"
        case .completed:
            return "完成待办后，它会出现在这里。"
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { taskPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    taskPendingDeletion = nil
                }
            }
        )
    }

    private func deleteTask(_ task: TaskItem) {
        if pomodoroTimerSelectionIs(task), pomodoroTimerCanChangeSelection {
            pomodoroTimer.selectTask(nil)
        }
        dataStore.deleteTask(task)
        taskPendingDeletion = nil
    }

    private func pomodoroTimerSelectionIs(_ task: TaskItem) -> Bool {
        pomodoroTimer.selectedTaskID == task.id
    }

    private var pomodoroTimerCanChangeSelection: Bool {
        pomodoroTimer.currentSession == nil
    }
}

private extension TaskGroupFilter {
    var groupID: UUID? {
        if case .group(let id) = self {
            return id
        }
        return nil
    }
}

struct TaskRow: View {
    @EnvironmentObject var dataStore: DataStore
    let task: TaskItem
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                dataStore.toggleTask(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.isCompleted)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)

                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        HStack(spacing: 8) {
                            PillBadge(text: task.priority.rawValue, color: priorityColor(task.priority))

                            if let groupName {
                                Label(groupName, systemImage: "folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if focusCount > 0 {
                                Label("\(focusCount) 次专注", systemImage: "timer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.top, 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("删除待办")
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("删除待办", role: .destructive, action: onDelete)
        }
    }

    private var groupName: String? {
        guard let groupID = task.groupID else { return nil }
        return dataStore.taskGroups.first { $0.id == groupID }?.name
    }

    private var focusCount: Int {
        dataStore.completedPomodoroSessions(for: task).count
    }

    private func priorityColor(_ priority: TaskItem.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct TaskDetailPopover: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var pomodoroTimer: PomodoroTimerController
    @Environment(\.dismiss) private var dismiss
    let taskID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let task {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.title2.weight(.bold))
                        Spacer()
                        PillBadge(text: task.priority.rawValue, color: priorityColor(task.priority))
                    }

                    if let groupName {
                        Label(groupName, systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }

                MetricStrip {
                    MetricCard(
                        title: "专注次数",
                        value: "\(sessions.count) 次",
                        caption: "完整完成的专注",
                        icon: "timer",
                        color: .green
                    )
                    MetricCard(
                        title: "专注总时长",
                        value: focusDurationText,
                        caption: "累计投入时间",
                        icon: "clock.fill",
                        color: .blue
                    )
                }

                if sessions.isEmpty {
                    Text("还没有关联的专注记录。把它设为下一轮专注待办，完成后统计会自动更新。")
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近专注")
                            .font(.headline)

                        ForEach(sessions.prefix(3)) { session in
                            HStack {
                                Text(session.startTime, style: .date)
                                Spacer()
                                Text(durationText(for: session))
                                    .fontWeight(.semibold)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                FilledActionButton(
                    title: pomodoroTimer.selectedTaskID == task.id ? "已设为下一轮专注" : "设为下一轮专注",
                    systemImage: "timer",
                    color: .green,
                    action: {
                        pomodoroTimer.selectTask(task)
                        dismiss()
                    }
                )
                .disabled(task.isCompleted || pomodoroTimer.currentSession != nil)

                if task.isCompleted {
                    Text("已完成的待办不会再设为新的专注目标。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if pomodoroTimer.currentSession != nil {
                    Text("当前专注结束后，才能切换关联待办。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("这个待办已被删除。")
                    .foregroundColor(.secondary)
            }
        }
        .padding(22)
    }

    private var task: TaskItem? {
        dataStore.tasks.first { $0.id == taskID }
    }

    private var sessions: [PomodoroSession] {
        guard let task else { return [] }
        return dataStore.completedPomodoroSessions(for: task)
            .sorted { $0.startTime > $1.startTime }
    }

    private var groupName: String? {
        guard let groupID = task?.groupID else { return nil }
        return dataStore.taskGroups.first { $0.id == groupID }?.name
    }

    private var focusDurationText: String {
        guard let task else { return "0 分钟" }
        let minutes = dataStore.focusMinutes(for: task)
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 {
            return remainder == 0 ? "\(hours) 小时" : "\(hours)小时\(remainder)分"
        }
        return "\(minutes) 分钟"
    }

    private func durationText(for session: PomodoroSession) -> String {
        let seconds = session.effectiveDurationSeconds
        if seconds < 60 {
            return "\(seconds) 秒"
        }

        let minutes = Int(ceil(Double(seconds) / 60))
        return "\(minutes) 分钟"
    }

    private func priorityColor(_ priority: TaskItem.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索待办...", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.appStroke)
        )
    }
}

struct AddTaskSheet: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var priority: TaskItem.Priority
    @Binding var groupID: UUID?
    let groups: [TaskGroup]
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        FormSheet(title: "新建待办") {
            VStack(alignment: .leading, spacing: 10) {
                Text("待办名称")
                    .font(.headline)
                TextField("例如：整理课程笔记第 2 节", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("补充说明")
                    .font(.headline)
                PromptTextEditor(
                    text: $description,
                    prompt: "写下完成标准、上下文或下一步。",
                    minHeight: 100
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("待办组")
                    .font(.headline)
                Picker("待办组", selection: $groupID) {
                    Text("未分组").tag(nil as UUID?)
                    ForEach(groups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("优先级")
                    .font(.headline)
                Picker("优先级", selection: $priority) {
                    ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }

            SheetActions(
                isSaveDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}

struct AddTaskGroupSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        FormSheet(title: "新建待办组", width: 360) {
            VStack(alignment: .leading, spacing: 10) {
                Text("分组名称")
                    .font(.headline)
                TextField("例如：课程学习", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            SheetActions(
                isSaveDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}
