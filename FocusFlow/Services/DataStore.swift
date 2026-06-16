import Foundation
import Combine

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var pomodoroSessions: [PomodoroSession] = []
    @Published var timeEntries: [TimeEntry] = []
    @Published var tasks: [TaskItem] = []
    @Published var workLogs: [WorkLog] = []
    @Published var habits: [Habit] = []
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

    // MARK: - 时间追踪操作
    func addTimeEntry(_ entry: TimeEntry) {
        timeEntries.append(entry)
        saveKey(timeEntries, forKey: "timeEntries")
    }

    func stopTimeEntry(_ entry: TimeEntry, endTime: Date = Date()) {
        var stoppedEntry = entry
        stoppedEntry.endTime = endTime

        if let index = timeEntries.firstIndex(where: { $0.id == entry.id }) {
            timeEntries[index] = stoppedEntry
        } else {
            timeEntries.append(stoppedEntry)
        }
        saveKey(timeEntries, forKey: "timeEntries")
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

    // MARK: - 打卡操作
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveKey(habits, forKey: "habits")
    }

    func toggleHabit(_ habit: Habit, date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            if let recordIndex = habits[index].records.firstIndex(where: {
                Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                habits[index].records[recordIndex].isCompleted.toggle()
                habits[index].records[recordIndex].date = date
            } else {
                let record = HabitRecord(date: date, isCompleted: true)
                habits[index].records.append(record)
            }
            saveKey(habits, forKey: "habits")
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveKey(habits, forKey: "habits")
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
