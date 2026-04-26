import SwiftUI
import Combine

@MainActor
final class StudyAppViewModel: ObservableObject {
    @Published var settings: TimerSettings
    @Published var currentPhase: SessionPhase = .study
    @Published var isRunning = false
    @Published var remainingSeconds: Int
    @Published var currentTask = ""
    @Published var manualRecordDate = Date()
    @Published var manualRecordMinutes = 25
    @Published var manualRecordTask = ""
    @Published var selectedDate = Date()
    @Published var selectedDiaryText = ""
    @Published private(set) var todaySummary = DayStudySummary()
    @Published private(set) var selectedDateTaskSummaries: [TaskSummary] = []
    @Published private(set) var studyRecords: [StudyRecord]
    @Published private(set) var diaryEntries: [DiaryEntry]
    @Published private(set) var todoItems: [TodoItem]

    private let calendar = Calendar.current
    private let storage = LocalStorage()
    private var timerTask: Task<Void, Never>?
    private var targetDate: Date?
    private var activeSessionInitialSeconds: Int?

    init() {
        let savedSettings = LocalStorage.load(TimerSettings.self, key: LocalStorage.settingsKey) ?? TimerSettings()
        let savedRecords = LocalStorage.load([StudyRecord].self, key: LocalStorage.recordsKey) ?? []
        let savedDiary = LocalStorage.load([DiaryEntry].self, key: LocalStorage.diaryKey) ?? []
        let savedTodoItems = LocalStorage.load([TodoItem].self, key: LocalStorage.todoItemsKey) ?? []

        settings = savedSettings
        studyRecords = savedRecords.sorted { $0.recordedAt > $1.recordedAt }
        diaryEntries = savedDiary
        todoItems = savedTodoItems.sorted(by: Self.todoSort)
        remainingSeconds = savedSettings.studyMinutes * 60

        loadDiary(for: selectedDate)
        refreshDerivedData()
    }

    deinit {
        timerTask?.cancel()
    }

    var formattedTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var totalRecordedMinutesToday: Int {
        todaySummary.totalMinutes
    }

    var timerSessionCountToday: Int {
        todaySummary.sessionCount
    }

    var selectedDateLabel: String {
        selectedDate.formatted(.dateTime.year().month().day().weekday())
    }

    var canStartStudyTimer: Bool {
        currentPhase == .breakTime || !currentTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var phaseProgress: Double {
        let total = max(durationForCurrentPhase, 1)
        return Double(total - remainingSeconds) / Double(total)
    }

    func syncTimer() {
        guard isRunning, let targetDate else { return }

        let seconds = max(0, Int(targetDate.timeIntervalSinceNow.rounded(.down)))
        remainingSeconds = seconds

        if seconds == 0 {
            finishCurrentPhase()
        }
    }

    func toggleTimer() {
        isRunning ? pauseTimer() : startTimer()
    }

    func startTimer() {
        guard canStartStudyTimer else { return }

        if remainingSeconds <= 0 {
            remainingSeconds = durationForCurrentPhase
        }

        if activeSessionInitialSeconds == nil {
            activeSessionInitialSeconds = remainingSeconds
        }

        targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.syncTimer()
            }
        }
    }

    func pauseTimer() {
        syncTimer()
        timerTask?.cancel()
        timerTask = nil
        targetDate = nil
        isRunning = false
    }

    func stopTimer() {
        syncTimer()
        timerTask?.cancel()
        timerTask = nil
        targetDate = nil
        isRunning = false

        if currentPhase == .study {
            saveCurrentStudySessionIfNeeded(using: elapsedStudySeconds)
        }

        currentPhase = .study
        remainingSeconds = settings.studyMinutes * 60
        activeSessionInitialSeconds = nil
    }

    func resetTimer() {
        timerTask?.cancel()
        timerTask = nil
        targetDate = nil
        isRunning = false
        currentPhase = .study
        remainingSeconds = settings.studyMinutes * 60
        activeSessionInitialSeconds = nil
    }

    func addManualRecord() {
        let record = StudyRecord(
            recordedAt: manualRecordDate,
            minutes: max(1, manualRecordMinutes),
            task: manualRecordTask.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .manual
        )

        studyRecords.insert(record, at: 0)
        persistRecords()
        refreshDerivedData()

        manualRecordDate = Date()
        manualRecordMinutes = settings.studyMinutes
        manualRecordTask = ""
    }

    func loadDiary(for date: Date) {
        selectedDiaryText = diaryEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) })?.text ?? ""
        refreshSelectedDateSummaries()
    }

    func saveDiaryForSelectedDate() {
        let trimmed = selectedDiaryText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let index = diaryEntries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            if trimmed.isEmpty {
                diaryEntries.remove(at: index)
            } else {
                diaryEntries[index].text = trimmed
            }
        } else if !trimmed.isEmpty {
            diaryEntries.append(DiaryEntry(date: selectedDate, text: trimmed))
        }

        storage.save(diaryEntries, key: LocalStorage.diaryKey)
    }

    func deleteDiaryForSelectedDate() {
        if let index = diaryEntries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            diaryEntries.remove(at: index)
        }
        selectedDiaryText = ""
        storage.save(diaryEntries, key: LocalStorage.diaryKey)
    }

    func updateStudyMinutes(_ minutes: Int) {
        settings.studyMinutes = minutes
        storage.save(settings, key: LocalStorage.settingsKey)

        if currentPhase == .study {
            applyDurationChange(newDuration: minutes * 60)
        }
    }

    func updateBreakMinutes(_ minutes: Int) {
        settings.breakMinutes = minutes
        storage.save(settings, key: LocalStorage.settingsKey)

        if currentPhase == .breakTime {
            applyDurationChange(newDuration: minutes * 60)
        }
    }

    func resetStudyRecords() {
        studyRecords.removeAll()
        storage.save(studyRecords, key: LocalStorage.recordsKey)
        refreshDerivedData()
    }

    func addTodoItem(title: String) {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        todoItems.insert(
            TodoItem(title: title),
            at: 0
        )

        sortTodoItems()
        persistTodoItems()
    }

    func setCurrentTask(title: String) {
        currentTask = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentPhase == .study && !isRunning {
            remainingSeconds = settings.studyMinutes * 60
            activeSessionInitialSeconds = nil
        }
    }

    func toggleTodoItem(itemID: UUID) {
        guard let itemIndex = todoItems.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        todoItems[itemIndex].isCompleted.toggle()
        sortTodoItems()
        persistTodoItems()
    }

    private var durationForCurrentPhase: Int {
        switch currentPhase {
        case .study:
            return settings.studyMinutes * 60
        case .breakTime:
            return settings.breakMinutes * 60
        }
    }

    private var elapsedStudySeconds: Int {
        guard currentPhase == .study else { return 0 }
        let initial = activeSessionInitialSeconds ?? settings.studyMinutes * 60
        return max(0, initial - remainingSeconds)
    }

    func deleteTodoItem(itemID: UUID) {
        todoItems.removeAll { $0.id == itemID }
        persistTodoItems()
    }

    private func finishCurrentPhase() {
        timerTask?.cancel()
        timerTask = nil
        targetDate = nil

        if currentPhase == .study {
            saveCurrentStudySessionIfNeeded(using: activeSessionInitialSeconds ?? settings.studyMinutes * 60)
        }

        currentPhase = currentPhase.next
        remainingSeconds = durationForCurrentPhase
        activeSessionInitialSeconds = nil
        startTimer()
    }

    private func saveCurrentStudySessionIfNeeded(using elapsedSeconds: Int) {
        let task = currentTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else { return }
        guard elapsedSeconds > 0 else { return }

        let minutes = max(1, Int(ceil(Double(elapsedSeconds) / 60.0)))
        let record = StudyRecord(
            recordedAt: Date(),
            minutes: minutes,
            task: task,
            source: .timer
        )
        studyRecords.insert(record, at: 0)
        persistRecords()
        refreshDerivedData()
    }

    private func persistRecords() {
        storage.save(studyRecords, key: LocalStorage.recordsKey)
    }

    private func persistTodoItems() {
        storage.save(todoItems, key: LocalStorage.todoItemsKey)
    }

    private func refreshDerivedData() {
        refreshTodaySummary()
        refreshSelectedDateSummaries()
    }

    private func refreshTodaySummary() {
        let todaysRecords = studyRecords.filter { calendar.isDateInToday($0.recordedAt) }
        todaySummary = DayStudySummary(
            totalMinutes: todaysRecords.reduce(0) { $0 + $1.minutes },
            sessionCount: todaysRecords.filter { $0.source == .timer }.count
        )
    }

    private func refreshSelectedDateSummaries() {
        let grouped = Dictionary(grouping: studyRecords.filter { calendar.isDate($0.recordedAt, inSameDayAs: selectedDate) }) { record in
            let trimmed = record.task.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "名前なしタスク" : trimmed
        }

        selectedDateTaskSummaries = grouped
            .map { key, value in
                TaskSummary(task: key, minutes: value.reduce(0) { $0 + $1.minutes })
            }
            .sorted {
                if $0.minutes != $1.minutes {
                    return $0.minutes > $1.minutes
                }
                return $0.task < $1.task
            }
    }

    private func applyDurationChange(newDuration: Int) {
        if isRunning {
            activeSessionInitialSeconds = max(activeSessionInitialSeconds ?? 0, newDuration)
            let elapsed = max(0, (activeSessionInitialSeconds ?? newDuration) - remainingSeconds)
            let adjustedRemaining = max(1, newDuration - elapsed)
            remainingSeconds = adjustedRemaining
            activeSessionInitialSeconds = newDuration
            targetDate = Date().addingTimeInterval(TimeInterval(adjustedRemaining))
        } else {
            remainingSeconds = newDuration
            activeSessionInitialSeconds = nil
        }
    }

    private func sortTodoItems() {
        todoItems.sort(by: Self.todoSort)
    }

    private static func todoSort(lhs: TodoItem, rhs: TodoItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return lhs.isCompleted == false
        }
        return lhs.createdAt > rhs.createdAt
    }
}
