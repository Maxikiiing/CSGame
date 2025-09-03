import SwiftUI

/// Game view where players are assigned to multiplier slots based on their deaths.
struct DeathsGameView: View {
    // MARK: - Game State
    /// Players participating in the current round (up to 8).
    @State private var roundPlayers: [Player] = []
    /// Index of the player currently being placed into a slot.
    @State private var currentIndex: Int = 0
    /// Array representing chosen multiplier slots; each holds a player or nil if unassigned.
    @State private var assignments: [Player?] = Array(repeating: nil, count: 8)
    /// Calculated score for the round once all players are placed.
    @State private var score: Int? = nil
    /// Error message shown when player data fails to load.
    @State private var dataError: String? = nil

    // MARK: - Config
    /// Multipliers applied to each slot when calculating the total deaths.
    let multipliers: [Double] = [1.0, 0.5, 0.5, 0.5, 0.2, 0.2, 0.1, 0.1]
    /// Target score the player aims to reach.
    let goal: Double = 100_000

    // MARK: - Derived
    /// Indicates whether every slot has a player assigned.
    private var allPlaced: Bool { !assignments.contains(where: { $0 == nil }) }
    /// Returns the player currently being placed, or nil if all have been placed.
    private var currentPlayer: Player? {
        guard currentIndex < roundPlayers.count else { return nil }
        return roundPlayers[currentIndex]
    }

    /// Computes the running score based on placed players and multipliers.
    private var currentScore: Int {
        var sum: Double = 0
        for i in 0..<assignments.count {
            if let p = assignments[i] {
                sum += Double(p.deaths) * multipliers[i]
            }
        }
        return Int(sum.rounded())
    }

    /// Progress towards the goal as a value between 0 and 1.
    private var progressValue: Double { min(Double(currentScore) / goal, 1.0) }
    /// Tint color for the progress bar, turning gold when the goal is reached.
    private var progressTint: Color {
        Double(currentScore) >= goal
            ? Color(red: 0.75, green: 0.6, blue: 0.0) // dark yellow / gold
            : .blue
    }

    // MARK: - Body
    /// Main view layout containing progress, slots, current player, and controls.
    var body: some View {
        VStack(spacing: 24) {
            // Header / Progress
            VStack(spacing: 6) {
                Text("💀 Goal: \(formatted(Int(goal))) deaths")
                    .font(.title2).bold()
                Text("Score: \(formatted(currentScore)) / \(formatted(Int(goal)))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                // Visual indicator of progress toward the goal.
                ProgressView(value: progressValue)
                    .tint(progressTint)
                    .animation(.easeInOut(duration: 0.5), value: progressValue)
            }

            // Either show the error view, or the game UI
            if let dataError {
                errorView(message: dataError)
            } else {
                // Slots
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(0..<multipliers.count, id: \.self) { index in
                        Button {
                            // When tapped, place the current player into this slot.
                            placeCurrentPlayer(in: index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(assignments[index] == nil ? Color.blue : Color.green, lineWidth: 2)
                                    .frame(height: 70)

                                VStack(spacing: 4) {
                                    Text("x\(String(format: "%.1f", multipliers[index]))")
                                        .font(.subheadline).bold()

                                    if let player = assignments[index] {
                                        Text(player.name).font(.caption)
                                    } else {
                                        Text("Tap to place")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        // Disable the slot when already filled or when no player is available.
                        .disabled(assignments[index] != nil || currentPlayer == nil || allPlaced)
                    }
                }

                Divider()

                // Current player or result
                if roundPlayers.isEmpty {
                    emptyDataView
                } else if let player = currentPlayer, !allPlaced {
                    currentPlayerCard(player)
                } else {
                    resultView
                }

                // Bottom actions
                HStack {
                    Button("New Game", action: startNewRound)
                        .buttonStyle(.borderedProminent)

                    if allPlaced, let score {
                        Text("Total: \(formatted(score))  •  Goal: \(formatted(Int(goal)))")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(colorFor(score: score))
                            .padding(.leading, 8)
                    }
                }

                Spacer()
            }
        }
        .padding()
        // Load a new round when the view appears.
        .onAppear(perform: startNewRound)
    }

    // MARK: - Subviews
    /// Card displaying stats for the player currently being placed.
    private func currentPlayerCard(_ p: Player) -> some View {
        VStack(spacing: 8) {
            Text("Current Player").font(.subheadline).foregroundColor(.secondary)

            VStack(spacing: 6) {
                Text(p.name).font(.title3).bold()
                HStack(spacing: 16) {
                    statPill("Deaths", p.deaths)
                    statPill("Kills", p.kills)
                    statPill("Aces", p.acesOrZero)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Pick a multiplier slot above.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    /// View shown after all players have been placed and the score computed.
    private var resultView: some View {
        VStack(spacing: 10) {
            Text("Round Complete").font(.headline)
            if let score {
                Text("Total Score: \(formatted(score))")
                    .font(.title3).bold()
                    .foregroundColor(colorFor(score: score))
            } else {
                Text("Calculating…").foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// View displayed when no player data could be loaded.
    private var emptyDataView: some View {
        VStack(spacing: 8) {
            Text("No players available").font(.headline)
            Text("Ensure players JSON is bundled and valid.")
                .font(.caption).foregroundColor(.secondary)
            Button("Reload") { startNewRound() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    /// Error view shown when loading player data fails.
    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Data Error").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") { startNewRound() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Small pill-style label showing a statistic title and value.
    private func statPill(_ title: String, _ value: Int) -> some View {
        VStack {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(formatted(value)).font(.caption).bold()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions / Logic
    /// Starts a new round by loading players and resetting state.
    private func startNewRound() {
        let source = loadPlayers()
        guard !source.isEmpty else {
            dataError = "No players loaded. Check that players_real_data.json is in the bundle and decodes correctly."
            roundPlayers = []
            assignments = Array(repeating: nil, count: 8)
            currentIndex = 0
            score = nil
            return
        }
        dataError = nil
        roundPlayers = Array(source.prefix(8))
        assignments = Array(repeating: nil, count: 8)
        currentIndex = 0
        score = nil
    }

    /// Places the currently selected player into the specified slot.
    private func placeCurrentPlayer(in slot: Int) {
        guard !allPlaced, assignments[slot] == nil, currentIndex < roundPlayers.count else { return }
        assignments[slot] = roundPlayers[currentIndex]
        currentIndex += 1
        // Once all players are placed, compute the final score.
        if currentIndex == roundPlayers.count { computeScore() }
    }

    /// Calculates the total score based on deaths and multipliers.
    private func computeScore() {
        var sum: Double = 0
        for i in 0..<assignments.count {
            if let p = assignments[i] {
                sum += Double(p.deaths) * multipliers[i]   // deaths scoring
            }
        }
        score = Int(sum.rounded())
    }

    // MARK: - Helpers
    /// Formats numbers with thousands separators for display.
    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// Chooses a color based on how close the score is to the goal.
    private func colorFor(score: Int) -> Color {
        let diff = abs(Double(score) - goal)
        switch diff {
        case 0..<2_000: return .green
        case 2_000..<10_000: return .orange
        default: return .red
        }
    }
}


