//
//  KillGameView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//

import SwiftUI

/// Game view where players are assigned to multiplier slots based on their kills.
struct KillsGameView: View {
    // MARK: - Game State
    /// Error message if player data fails to load.
    @State private var dataError: String? = nil
    /// Players selected for the current round (up to 8).
    @State private var roundPlayers: [Player] = []              // 8 players for this round
    /// Array of multiplier slots containing assigned players.
    @State private var assignments: [Player?] = Array(repeating: nil, count: 8)
    /// Index of the player currently presented to the user.
    @State private var currentIndex: Int = 0                    // which player is currently shown
    /// Optional reference to a player selected in the UI (currently unused).
    @State private var selectedPlayer: Player? = nil
    /// Final score once all players are placed.
    @State private var score: Int? = nil

    // MARK: - Constants
    /// Multipliers applied to each slot when calculating kills.
    let multipliers: [Double] = [1.0, 0.5, 0.5, 0.2, 0.2, 0.1, 0.1, 0.1]
    /// Goal value players aim to achieve.
    let goal: Double = 100000

    /// Whether every slot has been filled with a player.
    var allPlaced: Bool { !assignments.contains(where: { $0 == nil }) }
    /// Player currently being placed into a slot.
    var currentPlayer: Player? {
        guard currentIndex < roundPlayers.count else { return nil }
        return roundPlayers[currentIndex]
    }
    /// Calculated score based on kills and multipliers.
    private var currentScore: Int {
        var sum: Double = 0
        for i in 0..<assignments.count {
            if let p = assignments[i] {
                sum += Double(p.kills) * multipliers[i]
            }
        }
        return Int(sum.rounded())
    }

    /// Progress value: 0.0 ... 1.0 representing score vs goal.
    private var progressValue: Double {
        min(Double(currentScore) / goal, 1.0)
    }

    /// Progress color: blue normally, dark yellow if >= goal.
    private var progressTint: Color {
        if Double(currentScore) >= goal {
            // Dark yellow / gold-ish
            return Color(red: 0.75, green: 0.6, blue: 0.0)
        } else {
            return .blue
        }
    }
    
    
    // MARK: - Body
    /// Main view structure with score display, slots, and controls.
    var body: some View {
        VStack(spacing: 6) {
            Text("🎯 Goal: \(formatted(Int(goal))) kills")
                .font(.title2).bold()
            Text("Score: \(formatted(currentScore)) / \(formatted(Int(goal)))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Progress now reflects current score vs goal
            ProgressView(value: progressValue)
                .tint(progressTint)
                .animation(.easeInOut(duration: 0.5), value: progressValue)


            // MARK: - Multiplier Slots
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(0..<multipliers.count, id: \.self) { index in
                    Button {
                        // Assign current player to chosen slot
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
                                    Text(player.name)
                                        .font(.caption)
                                } else {
                                    Text("Tap to place")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    // Disable button if slot already filled or no current player available.
                    .disabled(assignments[index] != nil || currentPlayer == nil || allPlaced)
                }
            }



            Divider()

            // MARK: - Current Player (or Result)
            if let player = currentPlayer, !allPlaced {
                VStack(spacing: 8) {
                    Text("Current Player").font(.subheadline).foregroundColor(.secondary)
                    VStack(spacing: 6) {
                        Text(player.name).font(.title3).bold()
                        HStack(spacing: 16) {
                            statPill("Kills", player.kills)
                            statPill("Deaths", player.deaths)
                            statPill("Aces", player.acesOrZero)
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
            } else {
                VStack(spacing: 10) {
                    Text("Round Complete").font(.headline)
                    if let score = score {
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

            // MARK: - Bottom actions / summary
            HStack {
                Button("New Game", action: startNewRound)
                    .buttonStyle(.borderedProminent)

                if allPlaced, let score = score {
                    Text("Total: \(formatted(score))  •  Goal: \(formatted(Int(goal)))")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(colorFor(score: score))
                        .padding(.leading, 8)
                }
            }

            Spacer()
        }
        .padding()
        // Load initial data on appearance
        .onAppear(perform: startNewRound)
    }

    // MARK: - Actions / Logic
    /// Starts a new round by loading players and resetting state.
    private func startNewRound() {
        let source = loadPlayers()
        guard !source.isEmpty else {
            dataError = "No players loaded. Check that players_real_data.json is in the app bundle and decodes correctly."
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


    /// Places the current player into the specified multiplier slot.
    private func placeCurrentPlayer(in slot: Int) {
        guard !allPlaced, assignments[slot] == nil, currentIndex < roundPlayers.count else { return }
        assignments[slot] = roundPlayers[currentIndex]
        currentIndex += 1

        if currentIndex == roundPlayers.count {
            computeScore()
        }
    }

    /// Computes the total score based on assigned players and multipliers.
    private func computeScore() {
        var sum: Double = 0
        for i in 0..<assignments.count {
            if let p = assignments[i] {
                sum += Double(p.kills) * multipliers[i]
            }
        }
        score = Int(sum.rounded())
    }

    // MARK: - UI Helpers
    /// Displays a small pill with the given title and numeric value.
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

    /// Formats integers with thousands separators.
    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// Color indicating how close the score is to the goal.
    private func colorFor(score: Int) -> Color {
        let diff = abs(Double(score) - goal)
        switch diff {
        case 0..<2_000: return .green
        case 2_000..<10_000: return .orange
        default: return .red
        }
    }
}

