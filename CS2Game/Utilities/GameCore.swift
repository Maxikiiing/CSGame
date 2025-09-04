//
//  GameCore.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI
import Combine

// Which attribute is scored?
enum GameStatKey: Equatable {
    case kills
    case deaths
    case aces

    func value(for p: Player) -> Int {
        switch self {
        case .kills:  return p.kills
        case .deaths: return p.deaths
        case .aces:   return p.acesOrZero
        }
    }
}

struct GameConfig: Equatable {
    let title: String
    let goal: Int
    let multipliers: [Double] // 8 values (2×4)
    let stat: GameStatKey
}

struct Slot: Identifiable, Equatable {
    let id = UUID()
    let multiplier: Double
    var player: Player? = nil
}

/// Result of trying to place the current candidate.
enum PlacementOutcome {
    case placed        // placed, still players left to place
    case completed     // placed and round just completed
    case ignored       // could not place (slot already filled / no candidate)
}

final class GameViewModel: ObservableObject {
    @Published private(set) var config: GameConfig
    // 🚫 Nicht mehr @Published: große Arrays bringen Main-Thread-Druck ohne UI-Nutzen.
    private var allPlayers: [Player] = []
    private var availablePlayers: [Player] = []

    @Published var slots: [Slot] = []
    @Published var currentCandidate: Player?
    @Published var gameOver: Bool = false
    @Published var dataError: String?

    private var cancellables = Set<AnyCancellable>()
    private var currentCandidateIndex: Int?

    init(config: GameConfig) {
        self.config = config
        self.slots = config.multipliers.map { Slot(multiplier: $0) }
        startNewRound()
    }

    func startNewRound() {
        let source = DataLoader.shared.loadPlayers()
        guard !source.isEmpty else {
            dataError = "No players loaded. Check your remote URL / bundle JSON."
            allPlayers = []; availablePlayers = []
            slots = config.multipliers.map { Slot(multiplier: $0) }
            currentCandidate = nil
            currentCandidateIndex = nil
            gameOver = false
            return
        }

        dataError = nil
        allPlayers = source
        availablePlayers = source                  // kompletter Pool
        slots = config.multipliers.map { Slot(multiplier: $0) }
        gameOver = false
        currentCandidate = nil
        currentCandidateIndex = nil
        drawNextCandidate()
    }

    func drawNextCandidate() {
        guard !availablePlayers.isEmpty else {
            currentCandidate = nil
            currentCandidateIndex = nil
            return
        }
        let idx = Int.random(in: 0 ..< availablePlayers.count)
        currentCandidateIndex = idx
        currentCandidate = availablePlayers[idx]
    }

    /// Places the current candidate into the given slot.
    /// Returns a `PlacementOutcome` so the view can trigger the right haptic.
    func placeCandidate(in slotID: UUID) -> PlacementOutcome {
        guard let candidate = currentCandidate,
              let sIdx = slots.firstIndex(where: { $0.id == slotID && $0.player == nil }),
              let cIdx = currentCandidateIndex
        else { return .ignored }

        // Kandidat im Slot ablegen
        slots[sIdx].player = candidate

        // Aus dem Pool entfernen (O(1) amortisiert)
        availablePlayers.remove(at: cIdx)

        // Reset aktueller Kandidat
        currentCandidate = nil
        currentCandidateIndex = nil

        if slots.allSatisfy({ $0.player != nil }) {
            gameOver = true
            return .completed
        } else {
            drawNextCandidate()
            return .placed
        }
    }

    var runningTotal: Int {
        slots.reduce(0) { sum, slot in
            guard let p = slot.player else { return sum }
            let base = config.stat.value(for: p)
            return sum + Int((Double(base) * slot.multiplier).rounded())
        }
    }

    var progress: Double {
        guard config.goal > 0 else { return 0 }
        return min(Double(runningTotal) / Double(config.goal), 1.0)
    }

    var hasWon: Bool { gameOver && runningTotal >= config.goal }
}
