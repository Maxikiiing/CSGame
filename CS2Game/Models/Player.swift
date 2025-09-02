//
//  Player.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

// Player.swift
import Foundation

struct Player: Identifiable, Codable, Equatable {
    let name: String
    let kills: Int
    let deaths: Int

    // Optional because your JSON may not include these
    let assists: Int?
    let grenade: Int?
    let sniper: Int?
    let rifle: Int?
    let aces: Int?
    let fourKs: Int?
    let zeroKs: Int?
    let mapsPlayed: Int?

    let id: UUID = UUID()

    // Use CodingKeys to map snake_case JSON keys to camelCase
    private enum CodingKeys: String, CodingKey {
        case name, kills, deaths, assists, grenade, sniper, rifle, aces, mapsPlayed
        case fourKs = "four_Ks"
        case zeroKs = "zero_Ks"
    }

    // Convenience for UI where we expect a number
    var assistsOrZero: Int { assists ?? 0 }
    var grenadeOrZero: Int { grenade ?? 0 }
    var sniperOrZero: Int { sniper ?? 0 }
    var rifleOrZero: Int { rifle ?? 0 }
    var acesOrZero: Int { aces ?? 0 }
    var fourKsOrZero: Int { fourKs ?? 0 }
    var zeroKsOrZero: Int { zeroKs ?? 0 }
    var mapsPlayedOrZero: Int { mapsPlayed ?? 0 }
}


