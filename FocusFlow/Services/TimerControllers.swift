import AppKit
import Combine
import Foundation

@MainActor
final class PomodoroTimerController: ObservableObject {
    @Published var timeRemaining: Int
    @Published var totalTime: Int
    @Published var isRunning = false
    @Published var currentSession: PomodoroSession?
    @Published var taskName = ""
    @Published var selectedDuration: Int {
        didSet {
            guard currentSession == nil else { return }
            resetClock()
        }
    }

    let durations = [15, 25, 30, 45, 60]

    private let dataStore: DataStore
    private var timer: Timer?

    init(dataStore: DataStore, selectedDuration: Int = 25) {
        self.dataStore = dataStore
        self.selectedDuration = selectedDuration
        self.timeRemaining = selectedDuration * 60
        self.totalTime = selectedDuration * 60
    }

    var isPaused: Bool {
        currentSession != nil && !isRunning && timeRemaining < totalTime
    }

    var minutes: Int {
        timeRemaining / 60
    }

    var seconds: Int {
        timeRemaining % 60
    }

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var statusText: String {
        if isRunning {
            return "沉浸中"
        }

        if isPaused {
            return "已暂停"
        }

        return "准备开始"
    }

    func start() {
        timer?.invalidate()

        if currentSession == nil {
            currentSession = PomodoroSession(
                duration: selectedDuration,
                taskName: taskName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        currentSession = nil
        resetClock()
    }

    func complete() {
        pause()

        if let session = currentSession {
            dataStore.completePomodoroSession(session)
            currentSession = nil
            NSSound.beep()
        }

        resetClock()
    }

    private func tick() {
        guard isRunning else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        if timeRemaining <= 0 {
            complete()
        }
    }

    private func resetClock() {
        timeRemaining = selectedDuration * 60
        totalTime = selectedDuration * 60
    }
}

@MainActor
final class TimeTrackerController: ObservableObject {
    @Published var isTracking = false
    @Published var currentEntry: TimeEntry?
    @Published var selectedCategory = "深度工作"
    @Published var project = ""
    @Published var note = ""
    @Published var elapsedTime: TimeInterval = 0

    let categories = ["深度工作", "学习输入", "阅读沉淀", "训练健康", "恢复休息", "日常事务", "其他"]

    private let dataStore: DataStore
    private var timer: Timer?

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    var statusText: String {
        isTracking ? "正在记录" : "等待开始"
    }

    func start() {
        guard !isTracking else { return }

        timer?.invalidate()

        let entry = TimeEntry(
            category: selectedCategory,
            project: project.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        currentEntry = entry
        elapsedTime = 0
        isTracking = true
        dataStore.addTimeEntry(entry)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        let entry = currentEntry
        stopTimer()

        if let entry {
            dataStore.stopTimeEntry(entry)
        }

        currentEntry = nil
        project = ""
        note = ""
        elapsedTime = 0
    }

    func reset() {
        guard !isTracking else { return }
        currentEntry = nil
        elapsedTime = 0
    }

    private func tick() {
        guard isTracking, let currentEntry else { return }
        elapsedTime = Date().timeIntervalSince(currentEntry.startTime)
    }

    private func stopTimer() {
        isTracking = false
        timer?.invalidate()
        timer = nil
    }
}
