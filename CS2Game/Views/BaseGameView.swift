//
//  BaseGameView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI

struct BaseGameView: View {
    @StateObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let horizPadding: CGFloat = 20
            let gridSpacing: CGFloat = 10
            let columnsCount = 2 // 2 Spalten, 4 Reihen
            // Slots sollen etwas kleiner und zentriert sein, nicht volle Breite
            let maxGridWidth = min(W - 2*horizPadding, 340) // begrenze Gesamtbreite
            let colWidth = (maxGridWidth - gridSpacing) / 2
            let slotHeight = max(50, min(80, colWidth * 0.55))
            // Candidate-Card etwas kleiner
            let cardHeight = max(90, min(140, W * 0.35))

            ScrollView {
                VStack(alignment: .center, spacing: 14) {
                    // MARK: Header
                    Text(vm.config.title)
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 6) {
                        Text("Goal: \(format(vm.config.goal))  •  Score: \(format(vm.runningTotal))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: vm.progress)
                            .tint(vm.runningTotal >= vm.config.goal ? Color(red: 0.75, green: 0.6, blue: 0.0) : .blue)
                            .animation(.easeInOut(duration: 0.5), value: vm.progress)
                            .frame(maxWidth: 260)
                    }

                    // MARK: Main content
                    if let error = vm.dataError {
                        ErrorCard(message: error) { vm.startNewRound() }
                            .padding(.top, 6)
                    } else {
                        // 2×4 Grid kompakter, zentriert
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnsCount),
                            spacing: gridSpacing
                        ) {
                            ForEach(vm.slots) { slot in
                                SlotView(slot: slot, slotHeight: slotHeight)
                                    .frame(width: colWidth)
                                    .onTapGesture { vm.placeCandidate(in: slot.id) }
                                    .disabled(slot.player != nil || vm.currentCandidate == nil || vm.gameOver)
                                    .animation(.spring(duration: 0.3), value: slot.player?.id)
                            }
                        }
                        .frame(maxWidth: maxGridWidth)
                        .padding(.top, 6)

                        // Candidate / Result kompakter
                        Group {
                            if let p = vm.currentCandidate, !vm.gameOver {
                                CandidateCard(player: p, stat: vm.config.stat, height: cardHeight)
                                    .transition(.opacity.combined(with: .scale))
                            } else if !vm.slots.contains(where: { $0.player == nil }) {
                                ResultCard(total: vm.runningTotal,
                                           goal: vm.config.goal,
                                           success: vm.hasWon)
                                    .transition(.opacity)
                            } else {
                                EmptyHintCard()
                            }
                        }
                        .frame(maxWidth: 360) // schlanker als ganze Breite
                        .padding(.top, 8)

                        // New Game Button kompakter
                        VStack(spacing: 8) {
                            Button("New Game") { vm.startNewRound() }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: 200) // nicht volle Breite

                            if vm.gameOver {
                                Text("Total: \(format(vm.runningTotal))  •  Goal: \(format(vm.config.goal))")
                                    .font(.footnote)
                                    .bold()
                                    .foregroundStyle(colorFor(score: vm.runningTotal, goal: vm.config.goal))
                            }
                        }
                        .padding(.top, 6)
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Helpers

private func format(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

private func colorFor(score: Int, goal: Int) -> Color {
    let diff = abs(Double(score - goal))
    switch diff {
    case 0..<2_000: return .green
    case 2_000..<10_000: return .orange
    default: return .red
    }
}

// MARK: - Subviews

private struct SlotView: View {
    let slot: Slot
    let slotHeight: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(slot.player == nil ? Color.blue : Color.green, lineWidth: 2)
                .frame(height: slotHeight)

            VStack(spacing: 2) {
                Text("× \(slot.multiplier, specifier: "%.1f")")
                    .font(.caption).bold()

                if let p = slot.player {
                    Text(p.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.primary)
                } else {
                    Text("Tap")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct CandidateCard: View {
    let player: Player
    let stat: GameStatKey
    let height: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text("Current Player")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 8) {
                    pill("Kills", player.kills)
                    pill("Deaths", player.deaths)
                    pill("Aces", player.acesOrZero)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func pill(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(format(value)).font(.caption).bold()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ResultCard: View {
    let total: Int
    let goal: Int
    let success: Bool
    var body: some View {
        VStack(spacing: 6) {
            Text("Round Complete").font(.headline)
            Text("Total Score: \(format(total))")
                .font(.subheadline).bold()
                .foregroundStyle(success ? .green : colorFor(score: total, goal: goal))
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct EmptyHintCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Ready to place").font(.subheadline)
            Text("Tap a slot to place the highlighted player.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 6) {
            Text("Data Error").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: 120)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
