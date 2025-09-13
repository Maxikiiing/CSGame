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

    func value(for p: RichPlayer) -> Int {
        switch self {
        case .kills:  return p.kills
        case .deaths: return p.deaths
        case .aces:   return p.aces
        }
    }
}
private extension GameStatKey {
    var keyName: String {
        switch self {
        case .kills:  return "kills"
        case .deaths: return "deaths"
        case .aces:   return "aces"
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
    var player: RichPlayer? = nil
}

/// Result of trying to place the current candidate.
enum PlacementOutcome {
    case placed        // placed, still players left to place
    case completed     // placed and round just completed
    case ignored       // could not place (slot already filled / no candidate)
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var config: GameConfig

    // Große Arrays sind intern, um Render-Last gering zu halten
    private var allPlayers: [RichPlayer] = []
    private var availablePlayers: [RichPlayer] = []

    @Published var slots: [Slot] = []
    @Published var currentCandidate: RichPlayer?
    @Published var gameOver: Bool = false
    @Published var dataError: String?

    // Spinner / Anzeige
    @Published var isSpinning: Bool = false
    @Published var spinnerDisplayName: String?

    /// Globale Interaktionssperre (während Spin + 0.2s danach)
    @Published var isInteractionLocked: Bool = false

    // (optional) für spätere Features
    @Published private(set) var lastAddedValue: Int = 0

    private var currentCandidateIndex: Int?
    private var spinTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// Einheitliche Anzeige: während Spin der rollende Name, sonst der finale Kandidat.
    var displayedName: String? {
        isSpinning ? spinnerDisplayName : currentCandidate?.name
    }

    init(config: GameConfig) {
        self.config = config
        self.slots = config.multipliers.map { Slot(multiplier: $0) }
        startNewRound()
        NotificationCenter.default.publisher(for: .playersCacheReady)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // Nur automatisch neu starten, wenn wir gerade *keine* Daten hatten
                // (Fehler angezeigt oder leerer Pool).
                if self.allPlayers.isEmpty || self.dataError != nil || self.slots.isEmpty {
                    self.startNewRound()
                }
            }
            .store(in: &cancellables)

    }
    

    func startNewRound() {
        // laufenden Spin abbrechen
        cancelSpin()

        let source = DataLoader.shared.loadRichPlayers()
        guard !source.isEmpty else {
            dataError = "No players loaded. Check your remote URL / bundle JSON."
            allPlayers = []; availablePlayers = []
            slots = config.multipliers.map { Slot(multiplier: $0) }
            currentCandidate = nil
            currentCandidateIndex = nil
            spinnerDisplayName = nil
            isSpinning = false
            isInteractionLocked = false
            gameOver = false
            lastAddedValue = 0
            return
        }

        dataError = nil
        allPlayers = source
        availablePlayers = source                  // kompletter Pool
        slots = config.multipliers.map { Slot(multiplier: $0) }
        gameOver = false
        currentCandidate = nil
        currentCandidateIndex = nil
        spinnerDisplayName = nil
        isSpinning = false
        isInteractionLocked = false
        lastAddedValue = 0
        
        AnalyticsService.shared.event("base_round_start", params: [
            "title": config.title,
            "stat":  String(describing: config.stat),
            "goal":  config.goal
        ])

        // Start-Kandidat kommt ohne Spin
        drawNextCandidate()
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

    /// Places the current candidate into the given slot.
    /// Returns a `PlacementOutcome` so the view can trigger the right haptic.
    func placeCandidate(in slotID: UUID) -> PlacementOutcome {
        guard !isSpinning, !isInteractionLocked,
              let candidate = currentCandidate,
              let sIdx = slots.firstIndex(where: { $0.id == slotID && $0.player == nil }),
              let cIdx = currentCandidateIndex
        else { return .ignored }

        // Beitrag für evtl. Delta-Bedarf vorab berechnen
        let base = config.stat.value(for: candidate)
        let added = Int((Double(base) * slots[sIdx].multiplier).rounded())
        lastAddedValue = max(0, added)

        // Kandidat im Slot ablegen
        slots[sIdx].player = candidate

        // Aus dem Pool entfernen
        availablePlayers.remove(at: cIdx)

        // Reset aktueller Kandidat
        currentCandidate = nil
        currentCandidateIndex = nil

        if slots.allSatisfy({ $0.player != nil }) {
            gameOver = true
            saveLeaderboard()   // <<< Score sichern
            let success = (runningTotal >= config.goal)
            AnalyticsService.shared.event("base_round_complete", params: [
                "title":  config.title,
                "score":  runningTotal,
                "goal":   config.goal,
                "success": success
            ])

            return .completed
        } else {
            startSpinAndSelectNext()
            return .placed
        }

    }

    // MARK: - Slot-Machine Spin mit 0.2s Nachlauf-Sperre

    /// Startet eine 2.2s "Slot-Machine" Animation, die spinnerDisplayName updatet
    /// und am Ende den nächsten Kandidaten final setzt. Nach Spin bleiben die Slots
    /// noch 0.2s gesperrt, um den Übergang weicher zu machen.
    private func startSpinAndSelectNext(duration: Double = 2.2, postLock: Double = 0.2) {
        cancelSpin()
        guard !availablePlayers.isEmpty else {
            spinnerDisplayName = nil
            isSpinning = false
            isInteractionLocked = false
            currentCandidate = nil
            currentCandidateIndex = nil
            return
        }

        // Ab sofort sperren
        isInteractionLocked = true
        isSpinning = true
        spinnerDisplayName = nil

        spinTask = Task { [weak self] in
            guard let self else { return }
            let start = CFAbsoluteTimeGetCurrent()
            let end = start + duration

            // Nur Namen referenzieren (leichtgewichtig)
            let namePool = availablePlayers.map { $0.name }

            while CFAbsoluteTimeGetCurrent() < end && !Task.isCancelled {
                let now = CFAbsoluteTimeGetCurrent()
                let t = max(0.0, min(1.0, (now - start) / duration)) // 0…1
                let eased = easeOutCubic(t)
                let interval = lerp(0.05, 0.18, eased) // 50ms → 180ms

                if let anyName = namePool.randomElement() {
                    self.spinnerDisplayName = anyName
                }

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }

            // Finalen Kandidaten setzen
            let idx = Int.random(in: 0 ..< self.availablePlayers.count)
            self.currentCandidateIndex = idx
            self.currentCandidate = self.availablePlayers[idx]

            // Spin ist visuell vorbei …
            self.spinnerDisplayName = nil
            self.isSpinning = false

            // … aber Interaktion bleibt noch kurz gesperrt (0.2s)
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

    // Helpers
    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func easeOutCubic(_ t: Double) -> Double {
        let p = 1 - (1 - t) * (1 - t) * (1 - t)
        return p
    }

    // MARK: - Score/Progress

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
    // Eindeutiger Key pro Basismodus (Kills/Deaths/Aces)
    func modeKey() -> String {
        "base:\(config.stat.keyName)"
    }

    private func saveLeaderboard() {
        BaseLeaderboard.shared.addResult(modeKey: modeKey(), score: runningTotal)
    }
    func appWillResignActive() {
        cancelSpin()
        isInteractionLocked = false
    }


}

