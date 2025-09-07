//
//  BingoLeaderboard.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import Foundation

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let modeKey: String          // z.B. "weekly:2025-W36|4x4", "monthly:2025-09|4x4", "random|4x4"
    let elapsed: TimeInterval    // Sekunden
    let finishedAt: Date         // Abschluss-Zeitpunkt (lokal)

    init(modeKey: String, elapsed: TimeInterval, finishedAt: Date = Date()) {
        self.id = UUID()
        self.modeKey = modeKey
        self.elapsed = elapsed
        self.finishedAt = finishedAt
    }
}

final class BingoLeaderboard {
    static let shared = BingoLeaderboard()
    private init() {}

    private let storageKey = "BingoLeaderboard_v1"

    private var cache: [LeaderboardEntry] = {
        if let data = UserDefaults.standard.data(forKey: "BingoLeaderboard_v1"),
           let arr = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) {
            return arr
        }
        return []
    }()

    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addResult(modeKey: String, elapsed: TimeInterval) {
        let entry = LeaderboardEntry(modeKey: modeKey, elapsed: elapsed, finishedAt: Date())
        cache.append(entry)
        persist()
    }

    func top(modeKey: String, limit: Int = 5) -> [LeaderboardEntry] {
        cache
            .filter { $0.modeKey == modeKey }
            .sorted { $0.elapsed < $1.elapsed }
            .prefix(limit)
            .map { $0 }
    }

    func all(modeKey: String) -> [LeaderboardEntry] {
        cache.filter { $0.modeKey == modeKey }
              .sorted { $0.elapsed < $1.elapsed }
    }

    func clear(modeKey: String) {
        cache.removeAll { $0.modeKey == modeKey }
        persist()
    }
}
