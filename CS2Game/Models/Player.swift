//
//  Player.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

// Player.swift
import Foundation

/// Represents a single player's statistics.
/// Conforms to `Identifiable` for SwiftUI lists and `Codable` for JSON parsing.
struct Player: Identifiable, Codable, Equatable {
    /// Player's in-game name.
    let name: String
    /// Number of kills achieved by the player.
    let kills: Int
    /// Number of deaths of the player.
    let deaths: Int

    // Optional stats because the JSON may omit them.
    /// Total assists credited to the player.
    let assists: Int?
    /// Kills resulting from grenade throws.
    let grenade: Int?
    /// Kills made with sniper rifles.
    let sniper: Int?
    /// Kills made with rifles.
    let rifle: Int?
    /// Number of ace rounds (5 kills in a round).
    let aces: Int?
    /// Number of four-kill rounds (4Ks).
    let fourKs: Int?
    /// Number of rounds with zero kills.
    let zeroKs: Int?
    /// Total number of maps the player has participated in.
    let mapsPlayed: Int?

    /// Unique identifier generated for SwiftUI's `Identifiable` protocol.
    let id: UUID = UUID()

    /// Maps snake_case keys from the JSON to camelCase properties.
    private enum CodingKeys: String, CodingKey {
        case name, kills, deaths, assists, grenade, sniper, rifle, aces, mapsPlayed
        case fourKs = "four_Ks"
        case zeroKs = "zero_Ks"
    }

    // Convenience properties return zero when the optional value is nil.
    /// Assists count with a default of zero.
    var assistsOrZero: Int { assists ?? 0 }
    /// Grenade kill count with a default of zero.
    var grenadeOrZero: Int { grenade ?? 0 }
    /// Sniper kill count with a default of zero.
    var sniperOrZero: Int { sniper ?? 0 }
    /// Rifle kill count with a default of zero.
    var rifleOrZero: Int { rifle ?? 0 }
    /// Number of aces with a default of zero.
    var acesOrZero: Int { aces ?? 0 }
    /// Number of 4K rounds with a default of zero.
    var fourKsOrZero: Int { fourKs ?? 0 }
    /// Number of zero-kill rounds with a default of zero.
    var zeroKsOrZero: Int { zeroKs ?? 0 }
    /// Maps played with a default of zero.
    var mapsPlayedOrZero: Int { mapsPlayed ?? 0 }
}


