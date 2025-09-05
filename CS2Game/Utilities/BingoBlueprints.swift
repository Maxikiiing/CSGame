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

// MARK: - Baukasten: Slot-Blueprints (nur explizit gewünschte Typen)

enum BingoSlotBlueprint {
    case min(stat: BingoStatKey, choices: [Int])
    case max(stat: BingoStatKey, choices: [Int])
    case nationOneOf([Nation])
    case roleOneOf([Role])
    case rolesAllOf(pairs: [(Role, Role)])      // z. B. (Sniper, IGL)
    case teamHistoryOneOf([Team])
    case kdMin(choices: [Double])
    case kdMax(choices: [Double])

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
        case .rolesAllOf(let pairs):
            let (a, b) = pairs.randomElement(using: &rng)!
            return .rolesAllOf([a, b])
        case .teamHistoryOneOf(let teams):
            return .teamHistory(teams.randomElement(using: &rng)!)
        case .kdMin(let choices):
            return .kdMin(choices.randomElement(using: &rng)!)
        case .kdMax(let choices):
            return .kdMax(choices.randomElement(using: &rng)!)
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

    private static let KD_MIN_CHOICES           = [1.10, 1.15, 1.20]
    private static let KD_MAX_CHOICES           = [1.00]

    private static let TEAMS_MIN_CHOICES        = [3, 4]
    private static let TEAMS_MAX_CHOICES        = [1]

    private static let EDPI_MIN_CHOICES         = [1_000]
    private static let EDPI_MAX_CHOICES         = [700]

    // Rollen & Paare
    private static let COMMON_ROLES: [Role] = [.Sniper, .Rifler, .IGL]
    private static let TWO_ROLE_PAIRS: [(Role, Role)] = [(.Sniper, .IGL)]

    // Attribute-Pools
    private static let COMMON_NATIONS: [Nation] = [
        .France, .UnitedKingdom, .Israel, .Denmark, .Sweden, .Germany, .Ukraine, .Russia, .Finland
    ]
    private static let COMMON_TEAMS: [Team] = [
        .G2, .NAVI, .Vitality, .FaZe, .Astralis, .MOUZ, .ENCE, .Heroic, .Liquid, .Cloud9,
        .VirtusPro, .NIP, .Fnatic, .FURIA, .Complexity, .Spirit, .BIG
    ]

    static let defaultSet = BingoBlueprintSet(
        name: "default",
        blueprints: [
            // --- Stats (deine Vorgaben) ---
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

            // Rollen
            .roleOneOf(COMMON_ROLES),
            .rolesAllOf(pairs: TWO_ROLE_PAIRS),
            .min(stat: .rolesCount,    choices: [2]),

            // Team-Count (Historie)
            .min(stat: .teamsCount,    choices: TEAMS_MIN_CHOICES),
            .max(stat: .teamsCount,    choices: TEAMS_MAX_CHOICES),

            // eDPI
            .min(stat: .eDPI,          choices: EDPI_MIN_CHOICES),
            .max(stat: .eDPI,          choices: EDPI_MAX_CHOICES),

            // KD
            .kdMin(choices: KD_MIN_CHOICES),
            .kdMax(choices: KD_MAX_CHOICES),

            // Attribute
            .teamHistoryOneOf(COMMON_TEAMS),
            .nationOneOf(COMMON_NATIONS)
        ]
    )
}
