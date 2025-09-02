//
//  DataLoader.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

import Foundation

func loadPlayers() -> [Player] {
    guard let url = Bundle.main.url(forResource: "players_real_data", withExtension: "json") else {
        print("❌ DataLoader: players_real_data.json not found in bundle.")
        return []
    }
    do {
        let data = try Data(contentsOf: url)
        let players = try JSONDecoder().decode([Player].self, from: data)
        print("✅ DataLoader: loaded \(players.count) players.")
        return players.shuffled()
    } catch {
        print("❌ DataLoader: decode error:", error)
        return []
    }
}

