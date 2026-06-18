import Foundation
import Combine

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var pomodoroSessions: [PomodoroSession] = []
    @Published var tasks: [TaskItem] = []
    @Published var taskGroups: [TaskGroup] = []
    @Published var workLogs: [WorkLog] = []
    @Published var goals: [Goal] = []
    @Published var countdownEvents: [CountdownEvent] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadData()
    }

    // MARK: - 数据加载
    private func loadData() {
        pomodoroSessions = load(forKey: "pomodoroSessions") ?? []
        tasks = load(forKey: "tasks") ?? []
        taskGroups = load(forKey: "taskGroups") ?? []
        workLogs = load(forKey: "workLogs") ?? []
        goals = load(forKey: "goals") ?? []
        countdownEvents = load(forKey: "countdownEvents") ?? []
    }

    private func load<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    // MARK: - 单键保存（用于增量更新）
    private func saveKey<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            #if DEBUG
            print("[DataStore] 编码失败 (\(key)): \(error)")
            #endif
        }
    }

    // MARK: - 番茄钟操作
    func addPomodoroSession(_ session: PomodoroSession) {
        pomodoroSessions.append(session)
        saveKey(pomodoroSessions, forKey: "pomodoroSessions")
    }

    func completePomodoroSession(_ session: PomodoroSession, endTime: Date = Date()) {
        var completedSession = session
        completedSession.endTime = endTime
        completedSession.isCompleted = true

        if let index = pomodoroSessions.firstIndex(where: { $0.id == session.id }) {
            pomodoroSessions[index] = completedSession
        } else {
            pomodoroSessions.append(completedSession)
        }
        saveKey(pomodoroSessions, forKey: "pomodoroSessions")
    }

    // MARK: - 任务操作
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveKey(tasks, forKey: "tasks")
    }

    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            saveKey(tasks, forKey: "tasks")
        }
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveKey(tasks, forKey: "tasks")
    }

    func addTaskGroup(_ group: TaskGroup) {
        taskGroups.append(group)
        saveKey(taskGroups, forKey: "taskGroups")
    }

    func deleteTaskGroup(_ group: TaskGroup) {
        taskGroups.removeAll { $0.id == group.id }

        for index in tasks.indices where tasks[index].groupID == group.id {
            tasks[index].groupID = nil
        }

        saveKey(taskGroups, forKey: "taskGroups")
        saveKey(tasks, forKey: "tasks")
    }

    func completedPomodoroSessions(for task: TaskItem) -> [PomodoroSession] {
        pomodoroSessions.filter {
            $0.taskID == task.id && $0.isCompleted
        }
    }

    func completedPomodoroSessions(
        on date: Date,
        calendar: Calendar = .current
    ) -> [PomodoroSession] {
        pomodoroSessions.filter {
            $0.isCompleted && calendar.isDate($0.startTime, inSameDayAs: date)
        }
    }

    func focusSeconds(on date: Date, calendar: Calendar = .current) -> Int {
        completedPomodoroSessions(on: date, calendar: calendar)
            .reduce(0) { $0 + $1.effectiveDurationSeconds }
    }

    func focusMinutes(for task: TaskItem) -> Int {
        let seconds = completedPomodoroSessions(for: task)
            .reduce(0) { $0 + $1.effectiveDurationSeconds }
        return Int(ceil(Double(seconds) / 60))
    }

    // MARK: - 工作日志操作
    func workLog(for date: Date, calendar: Calendar = .current) -> WorkLog? {
        workLogs.first {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func addWorkLog(_ log: WorkLog) {
        if let index = workLogs.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: log.date)
        }) {
            workLogs[index] = log
        } else {
            workLogs.append(log)
        }
        saveKey(workLogs, forKey: "workLogs")
    }

    // MARK: - 目标操作
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveKey(goals, forKey: "goals")
    }

    func updateGoalProgress(_ goal: Goal, progress: Double) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].progress = min(100, max(0, progress))
            saveKey(goals, forKey: "goals")
        }
    }

    func addMilestone(to goal: Goal, milestone: Milestone) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].milestones.append(milestone)
            saveKey(goals, forKey: "goals")
        }
    }

    func toggleMilestone(_ milestone: Milestone, in goal: Goal) {
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }),
           let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.id == milestone.id }) {
            goals[goalIndex].milestones[milestoneIndex].isCompleted.toggle()
            goals[goalIndex].milestones[milestoneIndex].completedAt = goals[goalIndex].milestones[milestoneIndex].isCompleted ? Date() : nil

            let milestones = goals[goalIndex].milestones
            if !milestones.isEmpty {
                let completedCount = milestones.filter(\.isCompleted).count
                goals[goalIndex].progress = Double(completedCount) / Double(milestones.count) * 100
            }
            saveKey(goals, forKey: "goals")
        }
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveKey(goals, forKey: "goals")
    }

    // MARK: - 倒数日操作
    func addCountdownEvent(_ event: CountdownEvent) {
        countdownEvents.append(event)
        saveKey(countdownEvents, forKey: "countdownEvents")
    }

    func deleteCountdownEvent(_ event: CountdownEvent) {
        countdownEvents.removeAll { $0.id == event.id }
        saveKey(countdownEvents, forKey: "countdownEvents")
    }
}
