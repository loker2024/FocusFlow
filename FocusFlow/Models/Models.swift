import Foundation

// MARK: - 番茄钟模型
struct PomodoroSession: Codable, Identifiable {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: Int
    var durationSeconds: Int?
    var taskName: String
    var taskID: UUID?
    var isCompleted: Bool

    init(
        startTime: Date = Date(),
        duration: Int = 25,
        durationSeconds: Int? = nil,
        taskName: String = "",
        taskID: UUID? = nil
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.durationSeconds = durationSeconds
        self.taskName = taskName
        self.taskID = taskID
        self.isCompleted = false
    }

    var effectiveDurationSeconds: Int {
        durationSeconds ?? duration * 60
    }
}

// MARK: - 任务模型
struct TaskItem: Codable, Identifiable {
    var id: UUID
    var title: String
    var taskDescription: String
    var priority: Priority
    var groupID: UUID?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var tags: [String]

    init(
        title: String,
        description: String = "",
        priority: Priority = .medium,
        groupID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.priority = priority
        self.groupID = groupID
        self.isCompleted = false
        self.createdAt = Date()
        self.tags = []
    }

    enum Priority: String, Codable, CaseIterable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case urgent = "紧急"
    }
}

struct TaskGroup: Codable, Identifiable {
    var id: UUID
    var name: String
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

// MARK: - 工作日志模型
struct WorkLog: Codable, Identifiable {
    var id: UUID
    var date: Date
    var content: String
    var mood: String
    var productivity: Int

    init(date: Date = Date(), content: String = "", mood: String = "😊", productivity: Int = 3) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.mood = mood
        self.productivity = productivity
    }
}

// MARK: - 目标模型
struct Goal: Codable, Identifiable {
    var id: UUID
    var title: String
    var goalDescription: String
    var targetDate: Date
    var progress: Double {
        didSet { progress = min(100, max(0, progress)) }
    }
    var milestones: [Milestone]
    var createdAt: Date

    init(title: String, description: String = "", targetDate: Date, progress: Double = 0) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.targetDate = targetDate
        self.progress = min(100, max(0, progress))
        self.milestones = []
        self.createdAt = Date()
    }
}

struct Milestone: Codable, Identifiable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
    }
}

// MARK: - 倒数日模型
struct CountdownEvent: Codable, Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var icon: String
    var color: String
    var isRepeatYearly: Bool

    init(title: String, date: Date, icon: String = "📅", color: String = "blue", isRepeatYearly: Bool = false) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.icon = icon
        self.color = color
        self.isRepeatYearly = isRepeatYearly
    }

    func nextOccurrence(after referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: referenceDate)

        guard isRepeatYearly else {
            return calendar.startOfDay(for: date)
        }

        let originalComponents = calendar.dateComponents([.month, .day], from: date)
        let currentYear = calendar.component(.year, from: today)

        func occurrence(in year: Int) -> Date? {
            var components = DateComponents()
            components.year = year
            components.month = originalComponents.month
            components.day = originalComponents.day
            return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
        }

        if let thisYear = occurrence(in: currentYear), thisYear >= today {
            return thisYear
        }

        return occurrence(in: currentYear + 1) ?? calendar.startOfDay(for: date)
    }

    var nextOccurrenceDate: Date {
        nextOccurrence()
    }

    func daysRemaining(from referenceDate: Date = Date(), calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: today, to: nextOccurrence(after: referenceDate, calendar: calendar)).day ?? 0
    }

    var daysRemaining: Int {
        daysRemaining()
    }
}
