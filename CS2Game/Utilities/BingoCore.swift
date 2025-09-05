//
//  BingoCore.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI
import Combine

// MARK: - Int-Stat Keys für generische min/max/range-Bedingungen

enum BingoStatKey: String, Codable, CaseIterable {
    case kills, deaths, aces
    case grenade, sniper, rifle, four_Ks, zero_Ks, mapsPlayed
    case grandSlams, majors, sTierTrophies, hltvMVPs, majorMVPs
    case eDPI, age
    case rolesCount   // ← NEU: Anzahl der Rollentypen

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
        case .rolesCount:    return p.roles.count   // ← NEU
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
        case .rolesCount: return "Roles" // ← NEU
        }
    }
}

// MARK: - Lesbare Namen für UI

private extension Role {
    var displayName: String {
        switch self {
        case .IGL: return "IGL"
        case .Rifler: return "Rifler"
        case .Sniper: return "Sniper"
        case .other(let s): return s
        }
    }
}

// MARK: - Bedingungen (ohne CurrentTeam)

enum BingoCondition: Codable, Equatable {
    // Int-basierte Bedingungen
    case min(stat: BingoStatKey, value: Int)
    case max(stat: BingoStatKey, value: Int)
    case range(stat: BingoStatKey, min: Int, max: Int)

    // Attribute
    case nation(Nation)
    case role(Role)
    case teamHistory(Team)     // jemals im Team
    case ageRange(min: Int, max: Int)

    // KD (Double) separat, um JSON klar zu halten
    case kdMin(Double)
    case kdMax(Double)
    case kdRange(min: Double, max: Double)

    func matches(_ p: RichPlayer) -> Bool {
        switch self {
        case .min(let stat, let v):
            return stat.value(for: p) >= v
        case .max(let stat, let v):
            return stat.value(for: p) <= v
        case .range(let stat, let lo, let hi):
            let val = stat.value(for: p)
            return val >= lo && val <= hi

        case .nation(let n):
            return p.nation == n
        case .role(let r):
            return p.roles.contains(r)
        case .teamHistory(let t):
            return p.teamHistory.contains(t)
        case .ageRange(let lo, let hi):
            return p.age >= lo && p.age <= hi

        case .kdMin(let x):
            return p.kd >= x
        case .kdMax(let x):
            return p.kd <= x
        case .kdRange(let lo, let hi):
            return p.kd >= lo && p.kd <= hi
        }
    }

    // Öffentliche, kompakte UI-Beschreibung
    var text: String {
        switch self {
        case .min(let stat, let v):            return "≥ \(format(v)) \(stat.displayName)"
        case .max(let stat, let v):            return "≤ \(format(v)) \(stat.displayName)"
        case .range(let stat, let lo, let hi): return "\(format(lo))–\(format(hi)) \(stat.displayName)"
        case .nation(let n):                   return "Nation: \(n.displayName)"
        case .role(let r):                     return "Role: \(r.displayName)"
        case .teamHistory(let t):              return "Played for: \(t.displayName)"
        case .ageRange(let lo, let hi):        return "Age: \(lo)–\(hi)"
        case .kdMin(let x):                    return String(format: "KD ≥ %.2f", x)
        case .kdMax(let x):                    return String(format: "KD ≤ %.2f", x)
        case .kdRange(let lo, let hi):         return String(format: "KD %.2f–%.2f", lo, hi)
        }
    }

    // Codable

    private enum CodingKeys: String, CodingKey {
        case kind, stat, value, min, max, nation, role, team
    }
    private enum Kind: String, Codable {
        case min, max, range
        case nation, role, teamHistory, ageRange
        case kdMin, kdMax, kdRange
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .min:
            self = .min(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                        value: try c.decode(Int.self, forKey: .value))
        case .max:
            self = .max(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                        value: try c.decode(Int.self, forKey: .value))
        case .range:
            self = .range(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                          min: try c.decode(Int.self, forKey: .min),
                          max: try c.decode(Int.self, forKey: .max))

        case .nation:
            self = .nation(try c.decode(Nation.self, forKey: .nation))
        case .role:
            self = .role(try c.decode(Role.self, forKey: .role))
        case .teamHistory:
            self = .teamHistory(try c.decode(Team.self, forKey: .team))
        case .ageRange:
            self = .ageRange(min: try c.decode(Int.self, forKey: .min),
                             max: try c.decode(Int.self, forKey: .max))

        case .kdMin:
            self = .kdMin(try c.decode(Double.self, forKey: .value))
        case .kdMax:
            self = .kdMax(try c.decode(Double.self, forKey: .value))
        case .kdRange:
            self = .kdRange(min: try c.decode(Double.self, forKey: .min),
                            max: try c.decode(Double.self, forKey: .max))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .min(let s, let v):
            try c.encode(Kind.min, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(v, forKey: .value)

        case .max(let s, let v):
            try c.encode(Kind.max, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(v, forKey: .value)

        case .range(let s, let lo, let hi):
            try c.encode(Kind.range, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)

        case .nation(let n):
            try c.encode(Kind.nation, forKey: .kind)
            try c.encode(n, forKey: .nation)

        case .role(let r):
            try c.encode(Kind.role, forKey: .kind)
            try c.encode(r, forKey: .role)

        case .teamHistory(let t):
            try c.encode(Kind.teamHistory, forKey: .kind)
            try c.encode(t, forKey: .team)

        case .ageRange(let lo, let hi):
            try c.encode(Kind.ageRange, forKey: .kind)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)

        case .kdMin(let x):
            try c.encode(Kind.kdMin, forKey: .kind)
            try c.encode(x, forKey: .value)

        case .kdMax(let x):
            try c.encode(Kind.kdMax, forKey: .kind)
            try c.encode(x, forKey: .value)

        case .kdRange(let lo, let hi):
            try c.encode(Kind.kdRange, forKey: .kind)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)
        }
    }
}

// MARK: - Model-Strukturen & VM

struct BingoCell: Identifiable, Equatable, Codable {
    let id: UUID
    let condition: BingoCondition
    var player: RichPlayer? = nil

    init(id: UUID = UUID(), condition: BingoCondition, player: RichPlayer? = nil) {
        self.id = id
        self.condition = condition
        self.player = player
    }
}

struct BingoBoardDTO: Codable {
    let title: String
    let rows: Int
    let cols: Int
    let cells: [BingoCondition]
}

enum BingoBoardSource: Equatable {
    case random
    case remote(url: URL)
    case seeded(Int)
    case bundle(resource: String)

    static func weekly(bundleResource: String = "bingo_weekly") -> BingoBoardSource { .bundle(resource: bundleResource) }
    static func monthly(bundleResource: String = "bingo_monthly") -> BingoBoardSource { .bundle(resource: bundleResource) }
}

struct BingoConfig: Equatable {
    let title: String
    let rows: Int
    let cols: Int
    let source: BingoBoardSource
}

enum BingoPlacementOutcome {
    case placed
    case rejected
    case completed
    case ignored
}

@MainActor
final class BingoViewModel: ObservableObject {
    @Published private(set) var config: BingoConfig
    @Published var cells: [BingoCell] = []

    @Published var currentCandidate: RichPlayer?
    @Published var isSpinning: Bool = false
    @Published var spinnerDisplayName: String?
    @Published var isInteractionLocked: Bool = false
    @Published var gameOver: Bool = false
    @Published var dataError: String?

    var displayedName: String? { isSpinning ? spinnerDisplayName : currentCandidate?.name }

    // Für Button-State
    var canReroll: Bool {
        !isSpinning && !isInteractionLocked && !gameOver && !availablePlayers.isEmpty
    }

    private var allPlayers: [RichPlayer] = []
    private var availablePlayers: [RichPlayer] = []
    private var currentCandidateIndex: Int?
    private var spinTask: Task<Void, Never>?

    init(config: BingoConfig) {
        self.config = config
        startNewBoard()
    }

    func startNewBoard() {
        cancelSpin()
        gameOver = false
        isSpinning = false
        isInteractionLocked = false
        spinnerDisplayName = nil
        currentCandidate = nil
        currentCandidateIndex = nil
        dataError = nil

        let pool = RichDataLoader.shared.loadRichPlayers()
        guard !pool.isEmpty else {
            dataError = "No rich players loaded. Ensure players_real_data_v2.json exists in the bundle."
            cells = []
            allPlayers = []; availablePlayers = []
            return
        }
        allPlayers = pool
        availablePlayers = pool

        Task { @MainActor in
            switch config.source {
            case .random:
                self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols)
            case .seeded(let seed):
                self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols, seed: seed)
            case .remote(let url):
                if let remote = await BingoLoader.shared.fetchBoard(from: url),
                   remote.rows == config.rows, remote.cols == config.cols {
                    self.cells = remote.cells.map { BingoCell(condition: $0) }
                } else {
                    self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols)
                }
            case .bundle(let res):
                if let local = BingoLoader.shared.loadLocal(named: res),
                   local.rows == config.rows, local.cols == config.cols {
                    self.cells = local.cells.map { BingoCell(condition: $0) }
                } else {
                    self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols)
                }
            }

            drawNextCandidate()
        }
    }

    static func generateRandomBoard(rows: Int, cols: Int, seed: Int? = nil) -> [BingoCell] {
        let count = max(1, rows * cols)
        let conditions = BingoBlueprints.defaultSet.generateConditions(count: count, seed: seed)
        return conditions.map { BingoCell(condition: $0) }
    }

    private func drawNextCandidate() {
        guard !availablePlayers.isEmpty else {
            currentCandidate = nil
            currentCandidateIndex = nil
            return
        }
        let idx = Int.random(in: 0 ..< availablePlayers.count)
        currentCandidateIndex = idx
        currentCandidate = availablePlayers[idx]
    }

    /// Spieler platzieren, wenn Bedingung erfüllt ist.
    func placeCandidate(in cellID: UUID) -> BingoPlacementOutcome {
        guard !isSpinning, !isInteractionLocked,
              let candidate = currentCandidate,
              let cIdx = currentCandidateIndex,
              let i = cells.firstIndex(where: { $0.id == cellID && $0.player == nil })
        else { return .ignored }

        let cond = cells[i].condition
        if cond.matches(candidate) {
            cells[i].player = candidate
            availablePlayers.remove(at: cIdx)
            currentCandidate = nil
            currentCandidateIndex = nil

            if cells.allSatisfy({ $0.player != nil }) {
                gameOver = true
                return .completed
            } else {
                startSpinAndSelectNext()
                return .placed
            }
        } else {
            return .rejected
        }
    }

    /// Nutzer will ohne Platzieren einen neuen Kandidaten ziehen (mit Spin).
    func rerollCandidate() {
        guard !isSpinning, !isInteractionLocked, !availablePlayers.isEmpty else { return }
        startSpinAndSelectNext(exclude: currentCandidate)
    }

    // MARK: - Spin

    private func startSpinAndSelectNext(duration: Double = 2.2, postLock: Double = 0.2, exclude: RichPlayer? = nil) {
        cancelSpin()
        guard !availablePlayers.isEmpty else {
            spinnerDisplayName = nil
            isSpinning = false
            isInteractionLocked = false
            currentCandidate = nil
            currentCandidateIndex = nil
            return
        }

        isInteractionLocked = true
        isSpinning = true
        spinnerDisplayName = nil

        spinTask = Task { [weak self] in
            guard let self else { return }
            let start = CFAbsoluteTimeGetCurrent()
            let end = start + duration

            let spinNamePool = self.availablePlayers.map { $0.name }
            while CFAbsoluteTimeGetCurrent() < end && !Task.isCancelled {
                let now = CFAbsoluteTimeGetCurrent()
                let t = max(0.0, min(1.0, (now - start) / duration))
                let eased = easeOutCubic(t)
                let interval = lerp(0.05, 0.18, eased)

                if let anyName = spinNamePool.randomElement() {
                    self.spinnerDisplayName = anyName
                }

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }

            let filtered: [RichPlayer]
            if let ex = exclude {
                filtered = self.availablePlayers.filter { $0.id != ex.id }
            } else {
                filtered = self.availablePlayers
            }
            let pool = filtered.isEmpty ? self.availablePlayers : filtered

            let idx = Int.random(in: 0 ..< pool.count)
            let chosen = pool[idx]

            if let realIdx = self.availablePlayers.firstIndex(where: { $0.id == chosen.id }) {
                self.currentCandidateIndex = realIdx
            } else {
                self.currentCandidateIndex = Int.random(in: 0 ..< self.availablePlayers.count)
            }
            self.currentCandidate = chosen

            self.spinnerDisplayName = nil
            self.isSpinning = false
            if postLock > 0 {
                try? await Task.sleep(nanoseconds: UInt64(postLock * 1_000_000_000))
            }
            self.isInteractionLocked = false
        }
    }

    private func cancelSpin() {
        spinTask?.cancel()
        spinTask = nil
        spinnerDisplayName = nil
        isSpinning = false
        isInteractionLocked = false
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func easeOutCubic(_ t: Double) -> Double {
        let p = 1 - (1 - t) * (1 - t) * (1 - t)
        return p
    }
}
