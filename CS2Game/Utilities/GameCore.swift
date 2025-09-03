//
//  GameCore.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI
import Combine

// Welches Attribut wird gewertet?
enum GameStatKey: Equatable {
    case kills
    case deaths
    
    func value(for p: Player) -> Int {
        switch self {
        case .kills:  return p.kills
        case .deaths: return p.deaths
        }
    }
}

struct GameConfig: Equatable {
    let title: String            // z.B. "100 000 Kills"
    let goal: Int                // z.B. 100_000
    let multipliers: [Double]    // z.B. 8 Werte
    let stat: GameStatKey
}

struct Slot: Identifiable, Equatable {
    let id = UUID()
    let multiplier: Double
    var player: Player? = nil
}

final class GameViewModel: ObservableObject {
    @Published private(set) var config: GameConfig
    @Published private(set) var allPlayers: [Player] = []
    @Published private(set) var availablePlayers: [Player] = []
    @Published var slots: [Slot] = []
    @Published var currentCandidate: Player?
    @Published var gameOver: Bool = false
    @Published var dataError: String?
    
    init(config: GameConfig) {
        self.config = config
        self.slots = config.multipliers.map { Slot(multiplier: $0) }
        startNewRound()
    }
    
    func startNewRound() {
        let source = loadPlayers()
        guard !source.isEmpty else {
            dataError = "No players loaded. Check that players_real_data.json is in the app bundle and decodes correctly."
            allPlayers = []; availablePlayers = []
            slots = config.multipliers.map { Slot(multiplier: $0) }
            currentCandidate = nil
            gameOver = false
            return
        }
        dataError = nil
        allPlayers = source
        // Nimm 8 zufällige Spieler (so wie vorher)
        availablePlayers = Array(source.prefix(config.multipliers.count))
        slots = config.multipliers.map { Slot(multiplier: $0) }
        gameOver = false
        drawNextCandidate()
    }
    
    func drawNextCandidate() {
        guard !availablePlayers.isEmpty else {
            currentCandidate = nil
            return
        }
        currentCandidate = availablePlayers.randomElement()
    }
    
    func placeCandidate(in slotID: UUID) {
        guard let candidate = currentCandidate,
              let sIdx = slots.firstIndex(where: { $0.id == slotID && $0.player == nil }),
              let poolIdx = availablePlayers.firstIndex(where: { $0.id == candidate.id })
        else { return }
        
        slots[sIdx].player = candidate
        availablePlayers.remove(at: poolIdx)
        currentCandidate = nil
        
        if slots.allSatisfy({ $0.player != nil }) {
            gameOver = true
        } else {
            drawNextCandidate()
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
