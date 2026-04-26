import Foundation

final class LocalStorage {
    static let settingsKey = "pomodoro.settings"
    static let recordsKey = "pomodoro.records"
    static let diaryKey = "pomodoro.diary"
    static let todoItemsKey = "pomodoro.todoItems"

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()

    func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
