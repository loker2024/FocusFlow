import Foundation

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

@main
struct FocusFlowChecks {
    @MainActor
    static func main() {
        do {
            try runAllChecks()
            print("All FocusFlow checks passed.")
        } catch {
            fputs("FocusFlow check failed: \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func runAllChecks() throws {
        try checkYearlyCountdownUsesNextUpcomingOccurrence()
        try checkYearlyCountdownRollsPastDatesIntoNextYear()
        try checkOneOffCountdownCanReportPastEvents()
        try checkGoalProgressIsClamped()
        try checkCompletingPomodoroSessionStoresAndPersistsSession()
        try checkPomodoroSessionsStayLinkedToTasks()
        try checkActualFocusSecondsDriveTaskTotals()
        try checkDailyFocusTotalsUseSelectedCalendarDate()
        try checkFocusTimerDirectionsAndCustomDuration()
        try checkDeletingTaskGroupKeepsTasksAsUngrouped()
        try checkDeletingTaskPreservesFocusHistory()
        try checkLegacyTaskAndPomodoroDataStillDecode()
        try checkWorkLogForSameDayIsReplaced()
    }

    private static func checkYearlyCountdownUsesNextUpcomingOccurrence() throws {
        let event = CountdownEvent(
            title: "Birthday",
            date: date(year: 2024, month: 7, day: 3),
            isRepeatYearly: true
        )
        let referenceDate = date(year: 2026, month: 6, day: 16)

        try expect(
            event.nextOccurrence(after: referenceDate, calendar: calendar) == date(year: 2026, month: 7, day: 3),
            "yearly countdown should use this year's future occurrence"
        )
        try expect(
            event.daysRemaining(from: referenceDate, calendar: calendar) == 17,
            "yearly countdown should calculate days from start-of-day dates"
        )
    }

    private static func checkYearlyCountdownRollsPastDatesIntoNextYear() throws {
        let event = CountdownEvent(
            title: "Anniversary",
            date: date(year: 2024, month: 5, day: 1),
            isRepeatYearly: true
        )
        let referenceDate = date(year: 2026, month: 6, day: 16)

        try expect(
            event.nextOccurrence(after: referenceDate, calendar: calendar) == date(year: 2027, month: 5, day: 1),
            "yearly countdown should roll past dates into next year"
        )
    }

    private static func checkOneOffCountdownCanReportPastEvents() throws {
        let event = CountdownEvent(
            title: "Deadline",
            date: date(year: 2026, month: 6, day: 10)
        )
        let referenceDate = date(year: 2026, month: 6, day: 16)

        try expect(
            event.daysRemaining(from: referenceDate, calendar: calendar) == -6,
            "one-off countdown should report past events as negative days"
        )
    }

    @MainActor
    private static func checkGoalProgressIsClamped() throws {
        var goal = Goal(title: "Ship", targetDate: date(year: 2026, month: 7, day: 1), progress: 150)
        try expect(goal.progress == 100, "goal initializer should clamp progress above 100")

        goal.progress = -20
        try expect(goal.progress == 0, "goal progress setter should clamp progress below 0")

        let store = DataStore(defaults: makeDefaults())
        store.addGoal(Goal(title: "Learn", targetDate: date(year: 2026, month: 7, day: 1)))
        store.updateGoalProgress(store.goals[0], progress: 130)
        try expect(store.goals[0].progress == 100, "goal progress updates should clamp progress above 100")
    }

    @MainActor
    private static func checkCompletingPomodoroSessionStoresAndPersistsSession() throws {
        let defaults = makeDefaults()
        let store = DataStore(defaults: defaults)
        let startTime = date(year: 2026, month: 6, day: 16)
        let session = PomodoroSession(startTime: startTime, duration: 25, taskName: "Draft")

        store.completePomodoroSession(session, endTime: startTime.addingTimeInterval(25 * 60))

        try expect(store.pomodoroSessions.count == 1, "completed pomodoro should be stored")
        try expect(store.pomodoroSessions[0].isCompleted, "completed pomodoro should be marked complete")
        try expect(store.pomodoroSessions[0].taskName == "Draft", "completed pomodoro should keep its task name")

        let reloadedStore = DataStore(defaults: defaults)
        try expect(reloadedStore.pomodoroSessions.count == 1, "completed pomodoro should persist")
        try expect(reloadedStore.pomodoroSessions[0].isCompleted, "persisted pomodoro should stay complete")
    }

    @MainActor
    private static func checkPomodoroSessionsStayLinkedToTasks() throws {
        let store = DataStore(defaults: makeDefaults())
        let task = TaskItem(title: "Write report")
        store.addTask(task)

        let linkedSession = PomodoroSession(duration: 25, taskName: task.title, taskID: task.id)
        store.completePomodoroSession(linkedSession)
        store.completePomodoroSession(PomodoroSession(duration: 45, taskName: "Other"))

        try expect(
            store.completedPomodoroSessions(for: task).count == 1,
            "task focus count should only include sessions linked by task id"
        )
        try expect(
            store.focusMinutes(for: task) == 25,
            "task focus duration should sum linked completed sessions"
        )
    }

    @MainActor
    private static func checkActualFocusSecondsDriveTaskTotals() throws {
        let store = DataStore(defaults: makeDefaults())
        let task = TaskItem(title: "Short focus")
        store.addTask(task)
        store.completePomodoroSession(
            PomodoroSession(
                duration: 1,
                durationSeconds: 75,
                taskName: task.title,
                taskID: task.id
            )
        )

        try expect(
            store.focusMinutes(for: task) == 2,
            "task focus totals should use actual seconds and round partial minutes up"
        )
    }

    @MainActor
    private static func checkDailyFocusTotalsUseSelectedCalendarDate() throws {
        let store = DataStore(defaults: makeDefaults())
        let selectedDate = date(year: 2026, month: 6, day: 18)
        let nextDate = date(year: 2026, month: 6, day: 19)

        store.completePomodoroSession(
            PomodoroSession(
                startTime: selectedDate,
                duration: 1,
                durationSeconds: 75,
                taskName: "Review"
            )
        )
        store.completePomodoroSession(
            PomodoroSession(
                startTime: nextDate,
                duration: 25,
                taskName: "Tomorrow"
            )
        )

        try expect(
            store.completedPomodoroSessions(on: selectedDate, calendar: calendar).count == 1,
            "daily focus sessions should only include the selected calendar date"
        )
        try expect(
            store.focusSeconds(on: selectedDate, calendar: calendar) == 75,
            "daily focus total should use actual recorded seconds"
        )
    }

    @MainActor
    private static func checkFocusTimerDirectionsAndCustomDuration() throws {
        let controller = PomodoroTimerController(dataStore: DataStore(defaults: makeDefaults()))

        controller.direction = .countUp
        try expect(controller.displayedSeconds == 0, "count-up focus should begin at zero")
        controller.start()
        controller.tick()
        controller.pause()
        try expect(controller.displayedSeconds == 1, "count-up focus should increase each second")

        controller.reset()
        controller.direction = .countDown
        controller.selectedDuration = 37
        try expect(controller.displayedSeconds == 37 * 60, "countdown should accept a custom minute value")
        controller.start()
        controller.tick()
        controller.pause()
        try expect(controller.displayedSeconds == 37 * 60 - 1, "countdown focus should decrease each second")
        controller.reset()
    }

    @MainActor
    private static func checkDeletingTaskGroupKeepsTasksAsUngrouped() throws {
        let defaults = makeDefaults()
        let store = DataStore(defaults: defaults)
        let group = TaskGroup(name: "Course")

        store.addTaskGroup(group)
        store.addTask(TaskItem(title: "Review notes", groupID: group.id))
        store.deleteTaskGroup(group)

        try expect(store.taskGroups.isEmpty, "deleted task group should be removed")
        try expect(store.tasks[0].groupID == nil, "tasks in a deleted group should become ungrouped")

        let reloadedStore = DataStore(defaults: defaults)
        try expect(reloadedStore.tasks[0].groupID == nil, "ungrouped task state should persist")
    }

    @MainActor
    private static func checkDeletingTaskPreservesFocusHistory() throws {
        let defaults = makeDefaults()
        let store = DataStore(defaults: defaults)
        let task = TaskItem(title: "Temporary task")

        store.addTask(task)
        store.completePomodoroSession(
            PomodoroSession(duration: 25, taskName: task.title, taskID: task.id)
        )
        store.deleteTask(task)

        try expect(store.tasks.isEmpty, "deleted task should be removed")
        try expect(store.pomodoroSessions.count == 1, "deleting a task should preserve focus history")
        try expect(store.pomodoroSessions[0].taskID == task.id, "preserved focus history should keep its original task id")

        let reloadedStore = DataStore(defaults: defaults)
        try expect(reloadedStore.tasks.isEmpty, "task deletion should persist")
        try expect(reloadedStore.pomodoroSessions.count == 1, "preserved focus history should persist")
    }

    private static func checkLegacyTaskAndPomodoroDataStillDecode() throws {
        struct LegacyTaskItem: Encodable {
            let id: UUID
            let title: String
            let taskDescription: String
            let priority: TaskItem.Priority
            let isCompleted: Bool
            let createdAt: Date
            let completedAt: Date?
            let dueDate: Date?
            let tags: [String]
        }

        struct LegacyPomodoroSession: Encodable {
            let id: UUID
            let startTime: Date
            let endTime: Date?
            let duration: Int
            let taskName: String
            let isCompleted: Bool
        }

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let legacyTask = LegacyTaskItem(
            id: UUID(),
            title: "Old task",
            taskDescription: "",
            priority: .medium,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil,
            dueDate: nil,
            tags: []
        )
        let legacySession = LegacyPomodoroSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            duration: 25,
            taskName: "Old focus",
            isCompleted: true
        )

        let decodedTask = try decoder.decode(TaskItem.self, from: encoder.encode(legacyTask))
        let decodedSession = try decoder.decode(PomodoroSession.self, from: encoder.encode(legacySession))

        try expect(decodedTask.groupID == nil, "legacy tasks should decode as ungrouped")
        try expect(decodedSession.taskID == nil, "legacy pomodoro sessions should decode without task links")
        try expect(decodedSession.durationSeconds == nil, "legacy pomodoro sessions should decode without actual seconds")
    }

    @MainActor
    private static func checkWorkLogForSameDayIsReplaced() throws {
        let store = DataStore(defaults: makeDefaults())
        let morning = date(year: 2026, month: 6, day: 16)
        let afternoon = calendar.date(byAdding: .hour, value: 14, to: morning)!

        store.addWorkLog(WorkLog(date: morning, content: "Draft", mood: "happy", productivity: 3))
        store.addWorkLog(WorkLog(date: afternoon, content: "Final", mood: "strong", productivity: 5))

        try expect(store.workLogs.count == 1, "same-day work log should be replaced")
        try expect(store.workLog(for: morning, calendar: calendar)?.content == "Final", "latest same-day work log should be returned")
        try expect(store.workLog(for: morning, calendar: calendar)?.productivity == 5, "replacement work log should keep productivity")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw CheckFailure.failed(message)
        }
    }

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "FocusFlowChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }
}
