import AppKit
import Combine
import Foundation

enum FocusTimerDirection: String, CaseIterable {
    case countUp = "正向"
    case countDown = "反向"
}

@MainActor
final class PomodoroTimerController: ObservableObject {
    @Published var displayedSeconds: Int
    @Published var totalTime: Int
    @Published var isRunning = false
    @Published var currentSession: PomodoroSession?
    @Published var taskName = ""
    @Published var selectedTaskID: UUID?
    @Published var direction: FocusTimerDirection = .countDown {
        didSet {
            guard currentSession == nil else { return }
            resetClock()
        }
    }
    @Published var selectedDuration: Int {
        didSet {
            guard currentSession == nil else { return }
            if selectedDuration < 1 {
                selectedDuration = 1
                return
            }
            if selectedDuration > 720 {
                selectedDuration = 720
                return
            }
            resetClock()
        }
    }

    let durations = [15, 25, 30, 45, 60]

    private let dataStore: DataStore
    private var timer: Timer?

    init(dataStore: DataStore, selectedDuration: Int = 25) {
        self.dataStore = dataStore
        self.selectedDuration = selectedDuration
        self.displayedSeconds = selectedDuration * 60
        self.totalTime = selectedDuration * 60
    }

    var isPaused: Bool {
        currentSession != nil && !isRunning && elapsedSeconds > 0
    }

    var minutes: Int {
        displayedSeconds / 60
    }

    var seconds: Int {
        displayedSeconds % 60
    }

    var elapsedSeconds: Int {
        switch direction {
        case .countUp:
            return displayedSeconds
        case .countDown:
            return max(0, totalTime - displayedSeconds)
        }
    }

    var progress: Double {
        switch direction {
        case .countUp:
            return Double(displayedSeconds % 60) / 60
        case .countDown:
            guard totalTime > 0 else { return 0 }
            return Double(totalTime - displayedSeconds) / Double(totalTime)
        }
    }

    var statusText: String {
        if isRunning {
            return direction == .countUp ? "正向计时中" : "反向计时中"
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
                duration: direction == .countDown ? selectedDuration : 0,
                durationSeconds: nil,
                taskName: taskName.trimmingCharacters(in: .whitespacesAndNewlines),
                taskID: selectedTaskID
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

    func selectTask(_ task: TaskItem?) {
        guard currentSession == nil else { return }
        selectedTaskID = task?.id
        taskName = task?.title ?? ""
    }

    func complete() {
        pause()

        if var session = currentSession {
            let actualSeconds = max(1, elapsedSeconds)
            session.durationSeconds = actualSeconds
            session.duration = Int(ceil(Double(actualSeconds) / 60))
            dataStore.completePomodoroSession(session)
            currentSession = nil
            NSSound.beep()
        }

        resetClock()
    }

    func tick() {
        guard isRunning else { return }

        switch direction {
        case .countUp:
            displayedSeconds += 1
        case .countDown:
            if displayedSeconds > 0 {
                displayedSeconds -= 1
            }

            if displayedSeconds <= 0 {
                complete()
            }
        }
    }

    private func resetClock() {
        switch direction {
        case .countUp:
            displayedSeconds = 0
            totalTime = 0
        case .countDown:
            displayedSeconds = selectedDuration * 60
            totalTime = selectedDuration * 60
        }
    }
}
