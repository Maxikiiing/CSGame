//
//  BingoCore.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI
import Combine

enum BingoStatKey: String, Codable, CaseIterable {
    case kills
    case deaths
    case aces

    func value(for p: RichPlayer) -> Int {
        switch self {
        case .kills:  return p.kills
        case .deaths: return p.deaths
        case .aces:   return p.aces
        }
    }

    var displayName: String {
        switch self {
        case .kills: return "Kills"
        case .deaths: return "Deaths"
        case .aces: return "Aces"
        }
    }
}

enum BingoCondition: Codable, Equatable {
    case min(stat: BingoStatKey, value: Int)
    case max(stat: BingoStatKey, value: Int)
    case range(stat: BingoStatKey, min: Int, max: Int)
    case nation(Nation)

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
        }
    }

    var text: String {
        switch self {
        case .min(let stat, let v):            return "≥ \(format(v)) \(stat.displayName)"
        case .max(let stat, let v):            return "≤ \(format(v)) \(stat.displayName)"
        case .range(let stat, let lo, let hi): return "\(format(lo))–\(format(hi)) \(stat.displayName)"
        case .nation(let n):                   return "Nation: \(n.displayName)"
        }
    }

    private enum CodingKeys: String, CodingKey { case kind, stat, value, min, max, nation }
    private enum Kind: String, Codable { case min, max, range, nation }

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
            if let n = try? c.decode(Nation.self, forKey: .nation) {
                self = .nation(n)
            } else if let n = try? c.decode(Nation.self, forKey: .value) {
                self = .nation(n)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .nation, in: c, debugDescription: "Nation missing")
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .min(let stat, let v):
            try c.encode(Kind.min, forKey: .kind)
            try c.encode(stat, forKey: .stat)
            try c.encode(v, forKey: .value)
        case .max(let stat, let v):
            try c.encode(Kind.max, forKey: .kind)
            try c.encode(stat, forKey: .stat)
            try c.encode(v, forKey: .value)
        case .range(let stat, let lo, let hi):
            try c.encode(Kind.range, forKey: .kind)
            try c.encode(stat, forKey: .stat)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)
        case .nation(let n):
            try c.encode(Kind.nation, forKey: .kind)
            try c.encode(n, forKey: .nation)
        }
    }
}

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
        var rng = SeededGenerator(seed: seed ?? Int.random(in: 0...Int.max))
        let count = max(1, rows * cols)

        let killThresholds   = [15_000, 25_000, 35_000, 45_000, 60_000]
        let deathThresholds  = [10_000, 20_000, 30_000, 40_000, 50_000]
        let aceThresholds    = [50, 100, 150, 200, 300]

        func randomCondition() -> BingoCondition {
            switch BingoStatKey.allCases.randomElement(using: &rng)! {
                case .kills:  return .min(stat: .kills,  value: killThresholds.randomElement(using: &rng)!)
                case .deaths: return .min(stat: .deaths, value: deathThresholds.randomElement(using: &rng)!)
                case .aces:   return .min(stat: .aces,   value: aceThresholds.randomElement(using: &rng)!)
            }
        }

        return (0..<count).map { _ in BingoCell(condition: randomCondition()) }
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

            // Für den Spin zeigen wir die kompletten Namen an (lebendiger)
            let spinNamePool = self.availablePlayers.map { $0.name }

            // Loop
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

            // Finale Auswahl – möglichst nicht derselbe wie vorher
            let filtered: [RichPlayer]
            if let ex = exclude {
                filtered = self.availablePlayers.filter { $0.id != ex.id }
            } else {
                filtered = self.availablePlayers
            }
            let pool = filtered.isEmpty ? self.availablePlayers : filtered

            let idx = Int.random(in: 0 ..< pool.count)
            let chosen = pool[idx]

            // Index im echten 'availablePlayers' nachschlagen
            if let realIdx = self.availablePlayers.firstIndex(where: { $0.id == chosen.id }) {
                self.currentCandidateIndex = realIdx
            } else {
                // Fallback (sollte selten vorkommen)
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

// PRNG
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
