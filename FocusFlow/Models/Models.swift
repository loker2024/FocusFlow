import Foundation

// MARK: - 番茄钟模型
struct PomodoroSession: Codable, Identifiable {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: Int
    var taskName: String
    var isCompleted: Bool
    
    init(startTime: Date = Date(), duration: Int = 25, taskName: String = "") {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.taskName = taskName
        self.isCompleted = false
    }
}

// MARK: - 时间追踪模型
struct TimeEntry: Codable, Identifiable {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var category: String
    var project: String
    var note: String
    
    init(startTime: Date = Date(), category: String = "", project: String = "", note: String = "") {
        self.id = UUID()
        self.startTime = startTime
        self.category = category
        self.project = project
        self.note = note
    }
    
    var duration: TimeInterval {
        endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
}

// MARK: - 任务模型
struct TaskItem: Codable, Identifiable {
    var id: UUID
    var title: String
    var taskDescription: String
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var tags: [String]
    
    init(title: String, description: String = "", priority: Priority = .medium) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.priority = priority
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

// MARK: - 打卡模型
struct Habit: Codable, Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var frequency: Frequency
    var createdAt: Date
    var records: [HabitRecord]
    
    init(name: String, icon: String = "✅", frequency: Frequency = .daily) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.frequency = frequency
        self.createdAt = Date()
        self.records = []
    }
    
    enum Frequency: String, Codable, CaseIterable {
        case daily = "每天"
        case weekly = "每周"
        case monthly = "每月"
    }
    
    func record(on date: Date, calendar: Calendar = .current) -> HabitRecord? {
        records.first { record in
            calendar.isDate(record.date, inSameDayAs: date)
        }
    }
    
    func isCompleted(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        record(on: date, calendar: calendar)?.isCompleted == true
    }
    
    func currentStreak(endingAt date: Date = Date(), calendar: Calendar = .current) -> Int {
        var streak = 0
        var currentDate = calendar.startOfDay(for: date)
        
        while isCompleted(on: currentDate, calendar: calendar) {
            streak += 1
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            currentDate = previousDate
        }
        
        return streak
    }
}

struct HabitRecord: Codable, Identifiable {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var note: String
    
    init(date: Date = Date(), isCompleted: Bool = true, note: String = "") {
        self.id = UUID()
        self.date = date
        self.isCompleted = isCompleted
        self.note = note
    }
}

// MARK: - 目标模型
struct Goal: Codable, Identifiable {
    var id: UUID
    var title: String
    var goalDescription: String
    var targetDate: Date
    var progress: Double
    var milestones: [Milestone]
    var createdAt: Date
    
    init(title: String, description: String = "", targetDate: Date, progress: Double = 0) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.targetDate = targetDate
        self.progress = progress
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
