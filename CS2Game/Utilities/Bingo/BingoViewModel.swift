//
//  BingoViewModel.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 07.09.25.
//

import SwiftUI
import Combine

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

    // Einheitliche Fehlermeldung
    private static let genericErrorMessage =
        "Oops! Looks like, something went wrong. Make sure you have a connection to the internet or try again later!"

    init(config: BingoConfig) {
        self.config = config
        startNewBoard()
    }

    // MARK: - Public helpers (für die View)

    /// Weekly/Monthly Challenge? (gilt für remote- sowie bundle-Varianten)
    func isChallengeMode() -> Bool {
        switch config.source {
        case .remote(let url):
            let s = url.absoluteString.lowercased()
            return s.contains("/weekly/") || s.contains("/monthly/")
        case .bundle(let res):
            let r = res.lowercased()
            return r.contains("weekly") || r.contains("monthly")
        case .random, .seeded:
            return false
        }
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
            if url.absoluteString.contains("/weekly/") { return "weekly:\(name)|\(size)" }
            if url.absoluteString.contains("/monthly/") { return "monthly:\(name)|\(size)" }
            return "remote:\(name)|\(size)"
        }
    }

    // MARK: - Lifecycle

    func startNewBoard() {
        cancelSpin()
        gameOver = false
        isSpinning = false
        isInteractionLocked = false
        spinnerDisplayName = nil
        currentCandidate = nil
        currentCandidateIndex = nil

        // Reset Fehler & Timer
        dataError = nil
        resetTimer()

        let pool = RichDataLoader.shared.loadRichPlayers()
        guard !pool.isEmpty else {
            dataError = "No rich players loaded. Ensure players_real_data_v2.json exists in the bundle."
            cells = []; allPlayers = []; availablePlayers = []
            return
        }
        allPlayers = pool
        availablePlayers = pool

        Task { @MainActor in
            switch config.source {
            case .random:
                // Random bleibt Random
                self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols)

            case .seeded(let seed):
                self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols, seed: seed)

            case .remote(let url):
                if let remote = await BingoLoader.shared.fetchBoard(from: url) {
                    // Grid-Größe (und Titel) dynamisch vom Remote übernehmen
                    let newTitle = remote.title
                    let newRows  = remote.rows
                    let newCols  = remote.cols

                    // Config aktualisieren, damit Layout/ModeKey/Leaderboard die echte Größe kennen
                    self.config = BingoConfig(
                        title: newTitle.isEmpty ? self.config.title : newTitle,
                        rows: newRows,
                        cols: newCols,
                        source: self.config.source
                    )

                    // Zellen aus Remote übernehmen
                    self.cells = remote.cells.map { BingoCell(condition: $0) }
                } else {
                    // Challenge-Fehler → KEIN Random-Fallback
                    self.cells = []
                    self.dataError = Self.genericErrorMessage
                }


            case .bundle(let res):
                if let local = BingoLoader.shared.loadLocal(named: res) {
                    // Grid-Größe (und Titel) dynamisch vom Bundle-Board übernehmen
                    let newTitle = local.title
                    let newRows  = local.rows
                    let newCols  = local.cols

                    self.config = BingoConfig(
                        title: newTitle.isEmpty ? self.config.title : newTitle,
                        rows: newRows,
                        cols: newCols,
                        source: self.config.source
                    )

                    self.cells = local.cells.map { BingoCell(condition: $0) }
                } else {
                    // Wenn dieses Bundle-Board eine Challenge ist → KEIN Random-Fallback
                    if self.isChallengeMode() {
                        self.cells = []
                        self.dataError = Self.genericErrorMessage
                    } else {
                        // sonst: Random-Fallback
                        self.cells = Self.generateRandomBoard(rows: config.rows, cols: config.cols)
                    }
                }

            }

            // Nur Kandidaten ziehen, wenn kein Fehler
            if self.dataError == nil {
                self.resetToExistingBoard() // setzt Timer/Kandidat neu und leert Platzierungen
            } else {
                self.currentCandidate = nil
                self.currentCandidateIndex = nil
            }
        }
    }

    /// „Try Again“:
    /// - Bei Fehler: Board je nach Quelle erneut laden (ohne Random-Fallback bei Challenges).
    /// - Ohne Fehler: dieselbe Board-Konfiguration neu starten (Platzierungen löschen), kein neues Grid.
    func tryAgain() {
        cancelSpin()
        gameOver = false
        isSpinning = false
        isInteractionLocked = false
        spinnerDisplayName = nil
        currentCandidate = nil
        currentCandidateIndex = nil

        if dataError != nil {
            // Erneuter Ladeversuch
            dataError = nil
            Task { @MainActor in
                switch config.source {
                case .remote(let url):
                    if let remote = await BingoLoader.shared.fetchBoard(from: url) {
                        // Größe/Titel an Remote anpassen
                        let newTitle = remote.title
                        let newRows  = remote.rows
                        let newCols  = remote.cols

                        self.config = BingoConfig(
                            title: newTitle.isEmpty ? self.config.title : newTitle,
                            rows: newRows,
                            cols: newCols,
                            source: self.config.source
                        )

                        self.cells = remote.cells.map { BingoCell(condition: $0) }
                        self.resetToExistingBoard()
                    } else {
                        self.cells = []
                        self.dataError = Self.genericErrorMessage
                    }


                case .bundle(let res):
                    if let local = BingoLoader.shared.loadLocal(named: res) {
                        let newTitle = local.title
                        let newRows  = local.rows
                        let newCols  = local.cols

                        self.config = BingoConfig(
                            title: newTitle.isEmpty ? self.config.title : newTitle,
                            rows: newRows,
                            cols: newCols,
                            source: self.config.source
                        )

                        self.cells = local.cells.map { BingoCell(condition: $0) }
                        self.resetToExistingBoard()
                    } else {
                        self.cells = []
                        self.dataError = Self.genericErrorMessage
                    }


                case .random, .seeded:
                    // Fehler hier unwahrscheinlich – einfach neu starten
                    self.resetToExistingBoard()
                }
            }
        } else {
            // Kein Fehler: dasselbe Board erneut spielen
            resetToExistingBoard()
        }
    }

    /// Startet dasselbe Board neu: Platzierungen löschen, Timer zurücksetzen, Spielerpool auffüllen und neuen Kandidaten ziehen.
    private func resetToExistingBoard() {
        for i in cells.indices { cells[i].player = nil }
        availablePlayers = allPlayers
        resetTimer()
        drawNextCandidate()
    }

    // MARK: - Helpers

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
              dataError == nil,
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
        guard !isSpinning, !isInteractionLocked, dataError == nil, !availablePlayers.isEmpty else { return }
        startSpinAndSelectNext(exclude: currentCandidate)
    }

    private func startSpinAndSelectNext(duration: Double = 2.2, postLock: Double = 0.2, exclude: RichPlayer? = nil) {
        cancelSpin()
        guard dataError == nil, !availablePlayers.isEmpty else {
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

    // MARK: - Timer/Leaderboard

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
    func appWillResignActive() {
        cancelSpin()               // privater Helper existiert schon
        isInteractionLocked = false
    }
    // App verlässt den Vordergrund / View verschwindet → Spin/Lock sicher beenden

}
