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

// MARK: - Slot-Kind (für Limits & Gewichtung)

/// Abstrakter Typ eines Slots (für Limits/Zählung).
/// Beispiele:
///  - .min(.kills) ist ein anderer Typ als .min(.deaths)
///  - .kdMin ist ein anderer Typ als .kdMax
///  - nation / role / rolesAllOf / teamHistory sind eigene Typen
enum BingoSlotKind: Hashable {
    case min(BingoStatKey)
    case max(BingoStatKey)
    case nationOneOf
    case roleOneOf
    case rolesAllOf
    case teamHistoryOneOf
    case kdMin
    case kdMax
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

    /// Liefert den abstrakten Slot-Typ für Limits/Zählung.
    var kind: BingoSlotKind {
        switch self {
        case .min(let stat, _): return .min(stat)
        case .max(let stat, _): return .max(stat)
        case .nationOneOf:      return .nationOneOf
        case .roleOneOf:        return .roleOneOf
        case .rolesAllOf:       return .rolesAllOf
        case .teamHistoryOneOf: return .teamHistoryOneOf
        case .kdMin:            return .kdMin
        case .kdMax:            return .kdMax
        }
    }

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

// MARK: - Gewichtete Blueprints

struct WeightedBlueprint {
    let blueprint: BingoSlotBlueprint
    let weight: Int
    var kind: BingoSlotKind { blueprint.kind }

    init(_ blueprint: BingoSlotBlueprint, weight: Int = 1) {
        self.blueprint = blueprint
        self.weight = max(1, weight)
    }
}

// MARK: - Set von Blueprints + Generator (mit per-Typ-Limits & Gewichtung)

struct BingoBlueprintSet {
    let name: String
    let weighted: [WeightedBlueprint]

    /// Globales Default-Limit: max. wie oft ein Slot-Typ im Grid vorkommen darf,
    /// wenn kein spezifisches Limit für diesen Typ gesetzt ist.
    let maxPerKindDefault: Int

    /// Spezifische Limits pro Slot-Typ (Overrides).
    let perKindLimits: [BingoSlotKind: Int]

    init(
        name: String,
        weighted: [WeightedBlueprint],
        maxPerKindDefault: Int = 2,
        perKindLimits: [BingoSlotKind: Int] = [:]
    ) {
        self.name = name
        self.weighted = weighted
        self.maxPerKindDefault = max(1, maxPerKindDefault)
        self.perKindLimits = perKindLimits
    }

    /// Ermittelt das Limit für einen Typ (Override > Default).
    private func limit(for kind: BingoSlotKind) -> Int {
        return max(perKindLimits[kind] ?? maxPerKindDefault, 1)
    }

    /// Erzeugt `count` Zufalls-Bedingungen gemäß Gewichtung & Limits.
    /// Hinweis: Wenn die Summe aller Maxima < count ist, werden Limits weicher gehandhabt,
    /// um das Board dennoch zu füllen.
    func generateConditions(count: Int, seed: Int? = nil) -> [BingoCondition] {
        var rng = SeededGenerator(seed: seed ?? Int.random(in: 0...Int.max))
        var result: [BingoCondition] = []
        var usedPerKind: [BingoSlotKind: Int] = [:]

        // (Optional) Debug-Info
        #if DEBUG
        let distinctKinds = Set(weighted.map { $0.kind })
        let capacity = distinctKinds.reduce(0) { $0 + limit(for: $1) }
        if capacity < count {
            print("⚠️ BingoBlueprintSet '\(name)': Summe der Limits (\(capacity)) < Grid-Zellen (\(count)). " +
                  "Es könnte zu weicher Limitierung kommen, um das Board zu füllen.")
        }
        #endif

        for _ in 0..<count {
            // 1) Erlaubte Blueprints unter Limit filtern
            let allowed = weighted.filter { usedPerKind[$0.kind, default: 0] < limit(for: $0.kind) }

            // 2) Wähle aus allowed (falls leer, weichere Handhabung: kompletter Pool)
            let pool = allowed.isEmpty ? weighted : allowed

            // 3) Gewichtete Auswahl mit ein paar Versuchen, ein Item < Limit zu erwischen
            var chosen: WeightedBlueprint!
            var attempts = 0
            let maxAttempts = 24
            repeat {
                let idx = weightedRandomIndex(in: pool, using: &rng)
                let candidate = pool[idx]
                if usedPerKind[candidate.kind, default: 0] < limit(for: candidate.kind) || allowed.isEmpty {
                    chosen = candidate
                    break
                }
                attempts += 1
            } while attempts < maxAttempts

            if chosen == nil {
                chosen = pool.randomElement(using: &rng)!
            }

            // 4) Condition bauen + zählen
            let cond = chosen.blueprint.makeCondition(using: &rng)
            result.append(cond)
            usedPerKind[chosen.kind, default: 0] += 1
        }
        return result
    }

    // Gewichtete Index-Auswahl
    private func weightedRandomIndex<R: RandomNumberGenerator>(in items: [WeightedBlueprint], using rng: inout R) -> Int {
        let total = items.reduce(0) { $0 + $1.weight }
        var t = Int.random(in: 0..<total, using: &rng)
        for (i, wb) in items.enumerated() {
            t -= wb.weight
            if t < 0 { return i }
        }
        return max(0, items.indices.last ?? 0)
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

    // 👉 Neue Werte
    private static let ACES_MIN_CHOICES         = [50, 60]
    private static let FOURKS_MIN_CHOICES       = [400]
    private static let RIFLE_MIN_CHOICES        = [25_000, 30_000]

    // Rollen & Paare
    private static let COMMON_ROLES: [Role] = [.Sniper, .Rifler, .IGL]
    private static let TWO_ROLE_PAIRS: [(Role, Role)] = [(.Sniper, .IGL)]

    // Attribute-Pools
    private static let COMMON_NATIONS: [Nation] = [
        .France, .UnitedKingdom, .Israel, .Denmark, .Sweden, .Ukraine, .Russia, .Finland, .Mongolia, .Russia, .BosniaAndHerzegovina, .Canada, .Slovakia
    ]
    private static let COMMON_TEAMS: [Team] = [
        .G2, .NAVI, .Vitality, .FaZe, .Astralis, .MOUZ, .ENCE, .Heroic, .Liquid, .Cloud9,
        .VirtusPro, .NIP, .Fnatic, .FURIA, .Complexity, .Spirit, .MongolZ, .Falcons, .NIP
    ]

    /// Hilfs-Shortcut
    private static func W(_ bp: BingoSlotBlueprint, _ weight: Int) -> WeightedBlueprint {
        WeightedBlueprint(bp, weight: weight)
    }

    private static let LIMITS: [BingoSlotKind: Int] = [
        .min(.eDPI): 1,
        .min(.kills): 3,
        .min(.grandSlams): 1,
        .min(.majorMVPs): 1,
        .min(.age): 1,
        .max(.eDPI): 1,
        .max(.teamsCount): 1,
        .nationOneOf: 2,
        .rolesAllOf: 1,
    ]

    static let defaultSet = BingoBlueprintSet(
        name: "default",
        weighted: [
            // --- Stats (deine Vorgaben) ---
            W(.min(stat: .kills,         choices: KILL_MIN_CHOICES),          3),

            W(.min(stat: .deaths,        choices: MIN_DEATHS_CHOICES),        1),
            W(.max(stat: .deaths,        choices: MAX_DEATHS_CHOICES),        1),

            W(.min(stat: .grandSlams,    choices: GRAND_SLAM_CHOICES),        1),
            W(.min(stat: .majorMVPs,     choices: MAJOR_MVP_CHOICES),         1),
            W(.min(stat: .grenade,       choices: GRENADE_MIN_CHOICES),       2),
            W(.min(stat: .sniper,        choices: SNIPER_MIN_CHOICES),        2),
            W(.max(stat: .sniper,        choices: SNIPER_MAX_CHOICES),        1),

            W(.min(stat: .majors,        choices: MIN_MAJORS_CHOICES),        2),
            W(.min(stat: .sTierTrophies, choices: S_TIER_TROPHY_CHOICES),     1),

            // 👉 Neue Slottypen
            W(.min(stat: .aces,          choices: ACES_MIN_CHOICES),          1),
            W(.min(stat: .four_Ks,       choices: FOURKS_MIN_CHOICES),        1),
            W(.min(stat: .rifle,         choices: RIFLE_MIN_CHOICES),         1),

            // Alter
            W(.min(stat: .age,           choices: MIN_AGE_CHOICES),           1),
            W(.max(stat: .age,           choices: MAX_AGE_CHOICES),           1),

            // Rollen
            W(.roleOneOf(COMMON_ROLES),                                       2),
            W(.rolesAllOf(pairs: TWO_ROLE_PAIRS),                             1),
            W(.min(stat: .rolesCount,    choices: [2]),                       1),

            // Team-Count (Historie)
            W(.min(stat: .teamsCount,    choices: TEAMS_MIN_CHOICES),         2),
            W(.max(stat: .teamsCount,    choices: TEAMS_MAX_CHOICES),         1),

            // eDPI
            W(.min(stat: .eDPI,          choices: EDPI_MIN_CHOICES),          1),
            W(.max(stat: .eDPI,          choices: EDPI_MAX_CHOICES),          1),

            // KD
            W(.kdMin(choices: KD_MIN_CHOICES),                                 2),
            W(.kdMax(choices: KD_MAX_CHOICES),                                 1),

            // Attribute
            W(.teamHistoryOneOf(COMMON_TEAMS),                                 2),
            W(.nationOneOf(COMMON_NATIONS),                                    2)
        ],
        maxPerKindDefault: 2,
        perKindLimits: LIMITS
    )
}
