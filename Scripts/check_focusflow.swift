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
        try checkHabitCompletionAndCurrentStreakUseCalendarDays()
        try checkHabitWeeklyAndMonthlyStreakUseFrequencyPeriods()
        try checkGoalProgressIsClamped()
        try checkCompletingPomodoroSessionStoresAndPersistsSession()
        try checkWorkLogForSameDayIsReplaced()
        try checkHabitToggleReusesRecordForSameDay()
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

    private static func checkHabitCompletionAndCurrentStreakUseCalendarDays() throws {
        let today = date(year: 2026, month: 6, day: 16)
        var habit = Habit(name: "Read")
        habit.records = [
            HabitRecord(date: today),
            HabitRecord(date: date(year: 2026, month: 6, day: 15)),
            HabitRecord(date: date(year: 2026, month: 6, day: 14)),
            HabitRecord(date: date(year: 2026, month: 6, day: 13), isCompleted: false)
        ]

        try expect(
            habit.isCompleted(on: today, calendar: calendar),
            "habit should be completed on a day with a completed record"
        )
        try expect(
            habit.currentStreak(endingAt: today, calendar: calendar) == 3,
            "habit streak should stop at the first missing or incomplete day"
        )
    }

    private static func checkHabitWeeklyAndMonthlyStreakUseFrequencyPeriods() throws {
        let today = date(year: 2026, month: 6, day: 16)
        var weeklyHabit = Habit(name: "Review", frequency: .weekly)
        weeklyHabit.records = [
            HabitRecord(date: today),
            HabitRecord(date: date(year: 2026, month: 6, day: 9)),
            HabitRecord(date: date(year: 2026, month: 5, day: 26))
        ]

        try expect(
            weeklyHabit.currentStreak(endingAt: today, calendar: calendar) == 2,
            "weekly habit streak should count completed weeks and stop at the first missing week"
        )
        try expect(
            weeklyHabit.frequency.streakUnit == "周",
            "weekly habit streak unit should be weeks"
        )

        var monthlyHabit = Habit(name: "Plan", frequency: .monthly)
        monthlyHabit.records = [
            HabitRecord(date: today),
            HabitRecord(date: date(year: 2026, month: 5, day: 1)),
            HabitRecord(date: date(year: 2026, month: 3, day: 1))
        ]

        try expect(
            monthlyHabit.currentStreak(endingAt: today, calendar: calendar) == 2,
            "monthly habit streak should count completed months and stop at the first missing month"
        )
        try expect(
            monthlyHabit.frequency.streakUnit == "月",
            "monthly habit streak unit should be months"
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

    @MainActor
    private static func checkHabitToggleReusesRecordForSameDay() throws {
        let store = DataStore(defaults: makeDefaults())
        let morning = date(year: 2026, month: 6, day: 16)
        let afternoon = calendar.date(byAdding: .hour, value: 14, to: morning)!
        let habit = Habit(name: "Stretch")

        store.addHabit(habit)
        store.toggleHabit(store.habits[0], date: morning)
        store.toggleHabit(store.habits[0], date: afternoon)

        try expect(store.habits[0].records.count == 1, "same-day habit toggles should reuse the record")
        try expect(!store.habits[0].records[0].isCompleted, "second same-day habit toggle should mark incomplete")
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
