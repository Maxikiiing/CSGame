//
//  BingoBlueprints.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import Foundation

// MARK: - PRNG (Seed-fähig für reproduzierbare Boards)

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { self.state = UInt64(bitPattern: Int64(seed)) }
    mutating func next() -> UInt64 {
        var x = state
        x ^= x >> 12; x ^= x << 25; x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}

// MARK: - Baukasten: Slot-Blueprints (nur die explizit gewünschten Typen)

enum BingoSlotBlueprint {
    case min(stat: BingoStatKey, choices: [Int])
    case max(stat: BingoStatKey, choices: [Int])
    case nationOneOf([Nation])
    case roleOneOf([Role])
    case teamHistoryOneOf([Team])

    func makeCondition<R: RandomNumberGenerator>(using rng: inout R) -> BingoCondition {
        switch self {
        case .min(let stat, let choices):
            return .min(stat: stat, value: choices.randomElement(using: &rng)!)
        case .max(let stat, let choices):
            return .max(stat: stat, value: choices.randomElement(using: &rng)!)
        case .nationOneOf(let nations):
            return .nation(nations.randomElement(using: &rng)!)
        case .roleOneOf(let roles):
            return .role(roles.randomElement(using: &rng)!)
        case .teamHistoryOneOf(let teams):
            return .teamHistory(teams.randomElement(using: &rng)!)
        }
    }
}

// MARK: - Set von Blueprints + Generator

struct BingoBlueprintSet {
    let name: String
    let blueprints: [BingoSlotBlueprint]

    func generateConditions(count: Int, seed: Int? = nil) -> [BingoCondition] {
        var rng = SeededGenerator(seed: seed ?? Int.random(in: 0...Int.max))
        return (0..<count).map { _ in
            blueprints.randomElement(using: &rng)!.makeCondition(using: &rng)
        }
    }
}

// MARK: - Vorkonfigurierte Sets (exakt deine Slottypen & Werte)

enum BingoBlueprints {
    // --- Wertebereiche / Choices ---
    private static let KILL_MIN_CHOICES         = [30_000, 35_000, 40_000]

    private static let MIN_DEATHS_CHOICES       = [25_000, 30_000]
    private static let MAX_DEATHS_CHOICES       = [10_000, 15_000]

    private static let GRAND_SLAM_CHOICES       = [1, 2]
    private static let MAJOR_MVP_CHOICES        = [1, 2]
    private static let MIN_MAJORS_CHOICES       = [1, 2]

    private static let GRENADE_MIN_CHOICES      = [400, 500, 600]
    private static let SNIPER_MIN_CHOICES       = [15_000, 18_000]
    private static let SNIPER_MAX_CHOICES       = [1_000]

    private static let MIN_AGE_CHOICES          = [30, 32]
    private static let MAX_AGE_CHOICES          = [19, 20, 21]

    private static let S_TIER_TROPHY_CHOICES    = [20, 23, 25]

    // Rolle (einzelne spezifische Rolle)
    private static let COMMON_ROLES: [Role] = [.Sniper, .Rifler, .IGL]

    // Attribute-Pools
    private static let COMMON_NATIONS: [Nation] = [
        .France, .UnitedKingdom, .Israel, .Denmark, .Sweden, .Germany,
        .Poland, .Ukraine, .Russia, .Netherlands, .Belgium, .Finland
    ]
    private static let COMMON_TEAMS: [Team] = [
        .G2, .NAVI, .Vitality, .FaZe, .Astralis, .MOUZ, .ENCE, .Heroic, .Liquid, .Cloud9,
        .VirtusPro, .NIP, .Fnatic, .FURIA, .Complexity, .Spirit, .BIG
    ]

    static let defaultSet = BingoBlueprintSet(
        name: "default",
        blueprints: [
            // --- Stats ---
            .min(stat: .kills,         choices: KILL_MIN_CHOICES),

            .min(stat: .deaths,        choices: MIN_DEATHS_CHOICES),
            .max(stat: .deaths,        choices: MAX_DEATHS_CHOICES),

            .min(stat: .grandSlams,    choices: GRAND_SLAM_CHOICES),
            .min(stat: .majorMVPs,     choices: MAJOR_MVP_CHOICES),
            .min(stat: .grenade,       choices: GRENADE_MIN_CHOICES),
            .min(stat: .sniper,        choices: SNIPER_MIN_CHOICES),
            .max(stat: .sniper,        choices: SNIPER_MAX_CHOICES),

            .min(stat: .majors,        choices: MIN_MAJORS_CHOICES),
            .min(stat: .sTierTrophies, choices: S_TIER_TROPHY_CHOICES),

            // Alter
            .min(stat: .age,           choices: MIN_AGE_CHOICES),
            .max(stat: .age,           choices: MAX_AGE_CHOICES),

            // Rolle (konkrete) & Team-Historie & Nation
            .roleOneOf(COMMON_ROLES),
            .teamHistoryOneOf(COMMON_TEAMS),
            .nationOneOf(COMMON_NATIONS),

            // Min. Rollentypen (als Zahl via rolesCount)
            .min(stat: .rolesCount,    choices: [2])
        ]
    )
}
