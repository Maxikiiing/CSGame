//
//  DataLoader.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

import Foundation

/// Loads player data from a JSON file in the main bundle.
/// - Returns: An array of `Player` objects decoded from the bundled JSON file.
func loadPlayers() -> [Player] {
    // Locate the JSON file within the app bundle.
    guard let url = Bundle.main.url(forResource: "players_real_data", withExtension: "json") else {
        print("❌ DataLoader: players_real_data.json not found in bundle.")
        return []
    }
    do {
        // Load raw data from the located file.
        let data = try Data(contentsOf: url)
        // Decode the JSON into an array of Player structs.
        let players = try JSONDecoder().decode([Player].self, from: data)
        print("✅ DataLoader: loaded \(players.count) players.")
        // Shuffle the array for randomness in game rounds.
        return players.shuffled()
    } catch {
        // Log decoding or loading errors and return an empty array.
        print("❌ DataLoader: decode error:", error)
        return []
    }
}

