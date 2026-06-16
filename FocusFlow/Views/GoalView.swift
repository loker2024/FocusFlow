import SwiftUI

struct GoalView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddGoal = false
    @State private var newGoalTitle = ""
    @State private var newGoalDescription = ""
    @State private var newGoalTargetDate = Date().addingTimeInterval(30 * 24 * 3600)
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            HStack {
                Text("目标追踪")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showAddGoal = true }) {
                    Label("添加目标", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // 统计
            HStack {
                GoalStatCard(
                    title: "进行中",
                    count: dataStore.goals.filter { $0.progress < 100 }.count,
                    icon: "target",
                    color: .blue
                )
                
                GoalStatCard(
                    title: "已完成",
                    count: dataStore.goals.filter { $0.progress >= 100 }.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            // 目标列表
            List {
                ForEach(dataStore.goals) { goal in
                    GoalRow(goal: goal)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        dataStore.deleteGoal(dataStore.goals[index])
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding(40)
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(
                title: $newGoalTitle,
                description: $newGoalDescription,
                targetDate: $newGoalTargetDate,
                onSave: {
                    let goal = Goal(
                        title: newGoalTitle,
                        description: newGoalDescription,
                        targetDate: newGoalTargetDate
                    )
                    dataStore.addGoal(goal)
                    newGoalTitle = ""
                    newGoalDescription = ""
                    newGoalTargetDate = Date().addingTimeInterval(30 * 24 * 3600)
                    showAddGoal = false
                },
                onCancel: {
                    showAddGoal = false
                }
            )
        }
    }
}

struct GoalRow: View {
    @EnvironmentObject var dataStore: DataStore
    let goal: Goal
    @State private var showDetail = false
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: goal.targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                
                VStack(alignment: .trailing) {
                    Text("\(daysRemaining)天")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(daysRemaining < 7 ? .red : .primary)
                    
                    Text("剩余")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("进度")
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
            }
            
            // 里程碑
            if !goal.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
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
            
            // 添加里程碑按钮
            Button(action: { showDetail = true }) {
                Label("添加里程碑", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDetail) {
                AddMilestoneView(goal: goal)
                    .frame(width: 300)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddMilestoneView: View {
    @EnvironmentObject var dataStore: DataStore
    let goal: Goal
    @State private var milestoneTitle = ""
    
    var body: some View {
        VStack(spacing: 15) {
            Text("添加里程碑")
                .font(.headline)
            
            TextField("里程碑标题...", text: $milestoneTitle)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("取消") {
                    milestoneTitle = ""
                }
                
                Spacer()
                
                Button("添加") {
                    if !milestoneTitle.isEmpty {
                        let milestone = Milestone(title: milestoneTitle)
                        dataStore.addMilestone(to: goal, milestone: milestone)
                        milestoneTitle = ""
                    }
                }
                .disabled(milestoneTitle.isEmpty)
            }
        }
        .padding()
    }
}

struct GoalStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 150)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AddGoalSheet: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var targetDate: Date
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加新目标")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("目标标题")
                    .font(.headline)
                TextField("输入目标标题...", text: $title)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("目标描述")
                    .font(.headline)
                TextEditor(text: $description)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("目标日期")
                    .font(.headline)
                DatePicker("目标日期", selection: $targetDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
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

