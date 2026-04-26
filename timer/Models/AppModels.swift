import Foundation

struct TimerSettings: Codable, Equatable {
    var studyMinutes: Int = 25
    var breakMinutes: Int = 5
}

struct DayStudySummary: Equatable {
    var totalMinutes: Int = 0
    var sessionCount: Int = 0
}

struct StudyRecord: Identifiable, Codable {
    let id: UUID
    let recordedAt: Date
    let minutes: Int
    let task: String
    let source: RecordSource

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        minutes: Int,
        task: String,
        source: RecordSource
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.minutes = minutes
        self.task = task
        self.source = source
    }
}

struct DiaryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var text: String

    init(id: UUID = UUID(), date: Date, text: String) {
        self.id = id
        self.date = date
        self.text = text
    }
}

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var note: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

enum SessionPhase: String, Codable {
    case study
    case breakTime

    var title: String {
        switch self {
        case .study:
            return "Study"
        case .breakTime:
            return "Break"
        }
    }

    var actionTitle: String {
        switch self {
        case .study:
            return "Start Focus"
        case .breakTime:
            return "Start Break"
        }
    }

    var subtitle: String {
        switch self {
        case .study:
            return "タスクに集中しよう"
        case .breakTime:
            return "少し休んもう"
        }
    }

    var next: SessionPhase {
        switch self {
        case .study:
            return .breakTime
        case .breakTime:
            return .study
        }
    }
}

enum RecordSource: String, Codable {
    case timer
    case manual
}

enum AppTab: CaseIterable {
    case home
    case diary
    case todo
    case settings

    var title: String {
        switch self {
        case .home:
            return "ホーム"
        case .diary:
            return "日記"
        case .todo:
            return "Todo"
        case .settings:
            return "設定"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house"
        case .diary:
            return "book"
        case .todo:
            return "checklist"
        case .settings:
            return "line.3.horizontal"
        }
    }
}

struct TaskSummary: Identifiable, Equatable {
    let task: String
    let minutes: Int

    var id: String { task }
}
