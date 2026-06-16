import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskPriority: TaskItem.Priority = .medium
    @State private var searchText = ""
    @State private var filterStatus: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "全部"
        case pending = "待办"
        case completed = "已完成"
    }
    
    var filteredTasks: [TaskItem] {
        var tasks = dataStore.tasks
        
        // 搜索过滤
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.taskDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 状态过滤
        switch filterStatus {
        case .all:
            break
        case .pending:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        }
        
        return tasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    var body: some View {
        AppPage(
            title: "行动清单",
            subtitle: "把目标拆成今天能推进的一步，完成后就让它成为积累的一部分。",
            icon: "checklist",
            actionTitle: "添加行动",
            actionIcon: "plus",
            action: { showAddTask = true }
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
                
                HStack(spacing: 12) {
                    MetricCard(
                        title: "待推进",
                        value: "\(pendingCount) 项",
                        caption: "下一步越清楚，拖延越少",
                        icon: "circle",
                        color: .orange
                    )
                    MetricCard(
                        title: "已兑现",
                        value: "\(completedCount) 项",
                        caption: "完成会沉淀成信心",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    MetricCard(
                        title: "完成率",
                        value: "\(completionRate)%",
                        caption: dataStore.tasks.isEmpty ? "从第一项开始" : "保持稳定节奏",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                }
                
                List {
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            dataStore.deleteTask(filteredTasks[index])
                        }
                    }
                }
                .listStyle(.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.appStroke)
                )
                .overlay {
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            icon: searchText.isEmpty ? "checklist" : "magnifyingglass",
                            title: searchText.isEmpty ? "还没有行动项" : "没有匹配结果",
                            message: searchText.isEmpty ? "先写下一个 15 分钟内能开始的动作。" : "换个关键词，或者回到全部状态再看。"
                        )
                    }
                }
                .frame(minHeight: 340)
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(
                title: $newTaskTitle,
                description: $newTaskDescription,
                priority: $newTaskPriority,
                onSave: {
                    let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedDescription = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedTitle.isEmpty else { return }
                    
                    let task = TaskItem(
                        title: trimmedTitle,
                        description: trimmedDescription,
                        priority: newTaskPriority
                    )
                    dataStore.addTask(task)
                    resetNewTask()
                    showAddTask = false
                },
                onCancel: {
                    resetNewTask()
                    showAddTask = false
                }
            )
        }
    }
    
    private func resetNewTask() {
        newTaskTitle = ""
        newTaskDescription = ""
        newTaskPriority = .medium
    }
    
    private var pendingCount: Int {
        dataStore.tasks.filter { !$0.isCompleted }.count
    }
    
    private var completedCount: Int {
        dataStore.tasks.filter(\.isCompleted).count
    }
    
    private var completionRate: Int {
        guard !dataStore.tasks.isEmpty else { return 0 }
        return Int((Double(completedCount) / Double(dataStore.tasks.count) * 100).rounded())
    }
}

struct TaskRow: View {
    @EnvironmentObject var dataStore: DataStore
    let task: TaskItem
    
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
            
            VStack(alignment: .leading, spacing: 4) {
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
                
                HStack {
                    PillBadge(text: task.priority.rawValue, color: priorityColor(task.priority))
                    
                    Text(task.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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
            TextField("搜索行动项...", text: $text)
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
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加行动项")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("下一步")
                    .font(.headline)
                TextField("例如：完成一页复盘提纲", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("补充说明")
                    .font(.headline)
                PromptTextEditor(
                    text: $description,
                    prompt: "写下完成标准、上下文或可能的阻力。",
                    minHeight: 110
                )
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
            
            HStack {
                Button("取消", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("保存", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}
