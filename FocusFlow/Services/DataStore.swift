import Foundation
import Combine

class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var pomodoroSessions: [PomodoroSession] = []
    @Published var timeEntries: [TimeEntry] = []
    @Published var tasks: [TaskItem] = []
    @Published var workLogs: [WorkLog] = []
    @Published var habits: [Habit] = []
    @Published var goals: [Goal] = []
    @Published var countdownEvents: [CountdownEvent] = []
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        loadData()
    }
    
    // MARK: - 数据加载
    private func loadData() {
        pomodoroSessions = load(forKey: "pomodoroSessions") ?? []
        timeEntries = load(forKey: "timeEntries") ?? []
        tasks = load(forKey: "tasks") ?? []
        workLogs = load(forKey: "workLogs") ?? []
        habits = load(forKey: "habits") ?? []
        goals = load(forKey: "goals") ?? []
        countdownEvents = load(forKey: "countdownEvents") ?? []
    }
    
    private func load<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
    
    private func save() {
        save(pomodoroSessions, forKey: "pomodoroSessions")
        save(timeEntries, forKey: "timeEntries")
        save(tasks, forKey: "tasks")
        save(workLogs, forKey: "workLogs")
        save(habits, forKey: "habits")
        save(goals, forKey: "goals")
        save(countdownEvents, forKey: "countdownEvents")
    }
    
    private func save<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    
    // MARK: - 番茄钟操作
    func addPomodoroSession(_ session: PomodoroSession) {
        pomodoroSessions.append(session)
        save()
    }
    
    func completePomodoroSession(_ session: PomodoroSession) {
        if let index = pomodoroSessions.firstIndex(where: { $0.id == session.id }) {
            pomodoroSessions[index].endTime = Date()
            pomodoroSessions[index].isCompleted = true
            save()
        }
    }
    
    // MARK: - 时间追踪操作
    func addTimeEntry(_ entry: TimeEntry) {
        timeEntries.append(entry)
        save()
    }
    
    func stopTimeEntry(_ entry: TimeEntry) {
        if let index = timeEntries.firstIndex(where: { $0.id == entry.id }) {
            timeEntries[index].endTime = Date()
            save()
        }
    }
    
    // MARK: - 任务操作
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        save()
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            save()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }
    
    // MARK: - 工作日志操作
    func addWorkLog(_ log: WorkLog) {
        workLogs.append(log)
        save()
    }
    
    // MARK: - 打卡操作
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }
    
    func toggleHabit(_ habit: Habit, date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let record = HabitRecord(date: date, isCompleted: true)
            habits[index].records.append(record)
            save()
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
    }
    
    // MARK: - 目标操作
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        save()
    }
    
    func updateGoalProgress(_ goal: Goal, progress: Double) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].progress = min(100, max(0, progress))
            save()
        }
    }
    
    func addMilestone(to goal: Goal, milestone: Milestone) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].milestones.append(milestone)
            save()
        }
    }
    
    func toggleMilestone(_ milestone: Milestone, in goal: Goal) {
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }),
           let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.id == milestone.id }) {
            goals[goalIndex].milestones[milestoneIndex].isCompleted.toggle()
            goals[goalIndex].milestones[milestoneIndex].completedAt = goals[goalIndex].milestones[milestoneIndex].isCompleted ? Date() : nil
            save()
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        save()
    }
    
    // MARK: - 倒数日操作
    func addCountdownEvent(_ event: CountdownEvent) {
        countdownEvents.append(event)
        save()
    }
    
    func deleteCountdownEvent(_ event: CountdownEvent) {
        countdownEvents.removeAll { $0.id == event.id }
        save()
    }
}
