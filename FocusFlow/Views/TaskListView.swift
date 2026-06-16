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
        VStack(spacing: 20) {
            // 标题和添加按钮
            HStack {
                Text("任务管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showAddTask = true }) {
                    Label("添加任务", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 搜索和过滤
            HStack {
                SearchField(text: $searchText)
                
                Picker("状态", selection: $filterStatus) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            // 统计信息
            HStack {
                TaskStatBadge(title: "总任务", count: dataStore.tasks.count, color: .blue)
                TaskStatBadge(title: "待办", count: dataStore.tasks.filter { !$0.isCompleted }.count, color: .orange)
                TaskStatBadge(title: "已完成", count: dataStore.tasks.filter { $0.isCompleted }.count, color: .green)
            }
            
            // 任务列表
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
        }
        .padding(40)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(
                title: $newTaskTitle,
                description: $newTaskDescription,
                priority: $newTaskPriority,
                onSave: {
                    let task = TaskItem(
                        title: newTaskTitle,
                        description: newTaskDescription,
                        priority: newTaskPriority
                    )
                    dataStore.addTask(task)
                    newTaskTitle = ""
                    newTaskDescription = ""
                    newTaskPriority = .medium
                    showAddTask = false
                },
                onCancel: {
                    showAddTask = false
                }
            )
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject var dataStore: DataStore
    let task: TaskItem
    
    var body: some View {
        HStack {
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
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(task.priority))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(task.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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

struct TaskStatBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索任务...", text: $text)
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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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
            Text("添加新任务")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("任务标题")
                    .font(.headline)
                TextField("输入任务标题...", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("任务描述")
                    .font(.headline)
                TextEditor(text: $description)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
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
                    .disabled(title.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

