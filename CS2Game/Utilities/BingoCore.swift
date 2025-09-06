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

// MARK: - Flaggen-Emoji für Nationen

extension Nation {
    var flagEmoji: String {
        switch self {
        case .France:                   return "🇫🇷"
        case .UnitedKingdom:            return "🇬🇧"
        case .Israel:                   return "🇮🇱"
        case .Denmark:                  return "🇩🇰"
        case .Sweden:                   return "🇸🇪"
        case .Ukraine:                  return "🇺🇦"
        case .Russia:                   return "🇷🇺"
        case .Finland:                  return "🇫🇮"
        case .Mongolia:                 return "🇲🇳"
        case .BosniaAndHerzegovina:     return "🇧🇦"
        case .Canada:                   return "🇨🇦"
        case .Slovakia:                 return "🇸🇰"
        default:                        return "🏳️"
        }
    }
}

// MARK: - Bedingungen

enum BingoCondition: Codable, Equatable {
    // Int-basierte Bedingungen
    case min(stat: BingoStatKey, value: Int)
    case max(stat: BingoStatKey, value: Int)
    case range(stat: BingoStatKey, min: Int, max: Int)

    // Attribute
    case nation(Nation)
    case role(Role)
    case teamHistory(Team)
    case ageRange(min: Int, max: Int)
    case rolesAllOf([Role])

    // KD
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
        case .rolesAllOf(let roles):
            return roles.allSatisfy { p.roles.contains($0) }

        case .kdMin(let x):
            return p.kd >= x
        case .kdMax(let x):
            return p.kd <= x
        case .kdRange(let lo, let hi):
            return p.kd >= lo && p.kd <= hi
        }
    }

    // Kompakte UI-Beschreibung (Plain Text)
    var text: String {
        switch self {
        case .min(let stat, let v):            return "≥ \(format(v)) \(stat.displayName)"
        case .max(let stat, let v):            return "≤ \(format(v)) \(stat.displayName)"
        case .range(let stat, let lo, let hi): return "\(format(lo))–\(format(hi)) \(stat.displayName)"
        case .nation(let n):                   return n.displayName
        case .role(let r):                     return "Role: \(r.displayName)"
        case .teamHistory(let t):              return "Played for: \(t.displayName)"
        case .ageRange(let lo, let hi):        return "Age: \(lo)–\(hi)"
        case .rolesAllOf(let roles):
            let names = roles.map { $0.displayName }.joined(separator: " + ")
            return "Roles: \(names)"
        case .kdMin(let x):                    return String(format: "KD ≥ %.2f", x)
        case .kdMax(let x):                    return String(format: "KD ≤ %.2f", x)
        case .kdRange(let lo, let hi):         return String(format: "KD %.2f–%.2f", lo, hi)
        }
    }

    // Attributed UI-Beschreibung mit klein & fett hervorgehobenen Variablen
    var attributedText: AttributedString {
        var result = AttributedString(text)

        func bold(_ substring: String) {
            if let r = result.range(of: substring) {
                var container = AttributeContainer()
                container.font = .caption2.bold()   // klein & fett
                result[r].setAttributes(container)
            }
        }

        switch self {
        case .min(_, let v):
            bold("≥ \(format(v))")
        case .max(_, let v):
            bold("≤ \(format(v))")
        case .range(_, let lo, let hi):
            bold("\(format(lo))–\(format(hi))")
        case .nation(let n):
            bold(n.displayName)
        case .role(let r):
            bold(r.displayName)
        case .teamHistory(let t):
            bold(t.displayName)
        case .ageRange(let lo, let hi):
            bold("\(lo)–\(hi)")
        case .rolesAllOf(let roles):
            let names = roles.map { $0.displayName }.joined(separator: " + ")
            bold(names)
        case .kdMin(let x):
            bold(String(format: "≥ %.2f", x))
        case .kdMax(let x):
            bold(String(format: "≤ %.2f", x))
        case .kdRange(let lo, let hi):
            bold(String(format: "%.2f–%.2f", lo, hi))
        }

        return result
    }

    // Codable
    private enum CodingKeys: String, CodingKey {
        case kind, stat, value, min, max, nation, role, team, roles
    }
    private enum Kind: String, Codable {
        case min, max, range
        case nation, role, teamHistory, ageRange
        case rolesAllOf
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
        case .rolesAllOf:
            self = .rolesAllOf(try c.decode([Role].self, forKey: .roles))
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
        case .rolesAllOf(let roles):
            try c.encode(Kind.rolesAllOf, forKey: .kind)
            try c.encode(roles, forKey: .roles)
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

// MARK: - Helpers für UI (Nationserkennung)

extension BingoCondition {
    var isNationSlot: Bool {
        if case .nation = self { return true }
        return false
    }

    var nationFlag: String? {
        if case .nation(let n) = self { return n.flagEmoji }
        return nil
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
    var canReroll: Bool { !isSpinning && !isInteractionLocked && !gameOver && !availablePlayers.isEmpty }

    private var allPlayers: [RichPlayer] = []
    private var availablePlayers: [RichPlayer] = []
    private var currentCandidateIndex: Int?
    private var spinTask: Task<Void, Never>?

    // Timer/Leaderboard
    @Published var elapsed: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?
    private var hasPlacedFirst: Bool = false

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

        // Timer reset
        resetTimer()

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

    func placeCandidate(in cellID: UUID) -> BingoPlacementOutcome {
        guard !isSpinning, !isInteractionLocked,
              let candidate = currentCandidate,
              let cIdx = currentCandidateIndex,
              let i = cells.firstIndex(where: { $0.id == cellID && $0.player == nil })
        else { return .ignored }

        let cond = cells[i].condition
        if cond.matches(candidate) {
            if !hasPlacedFirst {
                startTimer()
                hasPlacedFirst = true
            }

            cells[i].player = candidate
            availablePlayers.remove(at: cIdx)
            currentCandidate = nil
            currentCandidateIndex = nil

            if cells.allSatisfy({ $0.player != nil }) {
                gameOver = true
                stopTimer()
                saveLeaderboard()
                return .completed
            } else {
                startSpinAndSelectNext()
                return .placed
            }
        } else {
            return .rejected
        }
    }

    func rerollCandidate() {
        guard !isSpinning, !isInteractionLocked, !availablePlayers.isEmpty else { return }
        startSpinAndSelectNext(exclude: currentCandidate)
    }

    // Spin
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

    // Timer/Leaderboard helpers

    private func resetTimer() {
        isTimerRunning = false
        elapsed = 0
        startDate = nil
        hasPlacedFirst = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func startTimer() {
        guard !isTimerRunning else { return }
        startDate = Date()
        isTimerRunning = true
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let s = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(s)
            }
    }

    private func stopTimer() {
        guard isTimerRunning else { return }
        if let s = startDate { elapsed = Date().timeIntervalSince(s) }
        isTimerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func saveLeaderboard() {
        let key = modeKey()
        BingoLeaderboard.shared.addResult(modeKey: key, elapsed: elapsed)
    }

    func modeKey() -> String {
        let size = "\(config.rows)x\(config.cols)"
        switch config.source {
        case .random:
            return "random|\(size)"
        case .seeded(let seed):
            return "seeded:\(seed)|\(size)"
        case .bundle(let res):
            return "bundle:\(res)|\(size)"
        case .remote(let url):
            let name = url.lastPathComponent
            if url.absoluteString.contains("/weekly/") {
                return "weekly:\(name)|\(size)"
            } else if url.absoluteString.contains("/monthly/") {
                return "monthly:\(name)|\(size)"
            } else {
                return "remote:\(name)|\(size)"
            }
        }
    }
}
