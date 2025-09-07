//
//  BingoStatKey.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 07.09.25.
//

import Foundation

enum BingoStatKey: String, Codable, CaseIterable {
    case kills, deaths, aces
    case grenade, sniper, rifle, four_Ks, zero_Ks, mapsPlayed
    case grandSlams, majors, sTierTrophies, hltvMVPs, majorMVPs
    case eDPI, age
    case rolesCount
    case teamsCount

    func value(for p: RichPlayer) -> Int {
        switch self {
        case .kills:         return p.kills
        case .deaths:        return p.deaths
        case .aces:          return p.aces
        case .grenade:       return p.grenade
        case .sniper:        return p.sniper
        case .rifle:         return p.rifle
        case .four_Ks:       return p.four_Ks
        case .zero_Ks:       return p.zero_Ks
        case .mapsPlayed:    return p.mapsPlayed
        case .grandSlams:    return p.grandSlams
        case .majors:        return p.majors
        case .sTierTrophies: return p.sTierTrophies
        case .hltvMVPs:      return p.hltvMVPs
        case .majorMVPs:     return p.majorMVPs
        case .eDPI:          return p.eDPI
        case .age:           return p.age
        case .rolesCount:    return p.roles.count
        case .teamsCount:    return p.teamHistory.count
        }
    }

    var displayName: String {
        switch self {
        case .kills: return "Kills"
        case .deaths: return "Deaths"
        case .aces: return "Aces"
        case .grenade: return "Grenade"
        case .sniper: return "Sniper"
        case .rifle: return "Rifle"
        case .four_Ks: return "4Ks"
        case .zero_Ks: return "0Ks"
        case .mapsPlayed: return "Maps"
        case .grandSlams: return "Intel Grand Slams"
        case .majors: return "Majors"
        case .sTierTrophies: return "S-Tier Trophies"
        case .hltvMVPs: return "HLTV MVPs"
        case .majorMVPs: return "Major MVPs"
        case .eDPI: return "eDPI"
        case .age: return "Age"
        case .rolesCount: return "Roles"
        case .teamsCount: return "Teams"
        }
    }
}
