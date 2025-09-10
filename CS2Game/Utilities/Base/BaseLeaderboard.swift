//
//  BaseLeaderboard.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

// Utilities/BaseLeaderboard.swift
import Foundation

struct BaseLeaderboardEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let modeKey: String        // z. B. "base:kills"
    let score: Int
    let finishedAt: Date

    init(modeKey: String, score: Int, finishedAt: Date = Date()) {
        self.id = UUID()
        self.modeKey = modeKey
        self.score = score
        self.finishedAt = finishedAt
    }
}

final class BaseLeaderboard {
    static let shared = BaseLeaderboard()
    private init() {}

    private let storageKey = "BaseLeaderboard_v1"

    private var cache: [BaseLeaderboardEntry] = {
        if let data = UserDefaults.standard.data(forKey: "BaseLeaderboard_v1"),
           let arr = try? JSONDecoder().decode([BaseLeaderboardEntry].self, from: data) {
            return arr
        }
        return []
    }()

    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // Speichert einen Versuch
    func addResult(modeKey: String, score: Int) {
        let entry = BaseLeaderboardEntry(modeKey: modeKey, score: score, finishedAt: Date())
        cache.append(entry)
        persist()
    }

    // Top N Scores für einen Modus (höchster Score zuerst)
    func top(modeKey: String, limit: Int = 5) -> [BaseLeaderboardEntry] {
        cache
            .filter { $0.modeKey == modeKey }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    // Alle Einträge eines Modus (optional)
    func all(modeKey: String) -> [BaseLeaderboardEntry] {
        cache
            .filter { $0.modeKey == modeKey }
            .sorted { $0.score > $1.score }
    }

    func clear(modeKey: String) {
        cache.removeAll { $0.modeKey == modeKey }
        persist()
    }
    func clearAll() {
        cache.removeAll()
        persist()
    }
}
