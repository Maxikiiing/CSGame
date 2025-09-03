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
            let columnsCount = 2 // 2 columns × 4 rows

            // Center a compact grid (not full width)
            let maxGridWidth = min(W - 2*horizPadding, 340)
            let colWidth = (maxGridWidth - gridSpacing) / 2

            // Compact slots
            let slotHeight = max(48, min(74, colWidth * 0.52))

            // Slim candidate card
            let cardHeight = max(76, min(110, W * 0.28))

            ScrollView {
                VStack(alignment: .center, spacing: 14) {
                    // MARK: Header
                    Text(vm.config.title)
                        .font(.title).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 6) {
                        Text("Goal: \(format(vm.config.goal))  •  Score: \(format(vm.runningTotal))")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ctBlueDim)

                        ProgressView(value: vm.progress)
                            .tint(Theme.ctBlue)
                            .animation(.easeInOut(duration: 0.5), value: vm.progress)
                            .frame(maxWidth: 260)
                    }

                    // MARK: Main content
                    if let error = vm.dataError {
                        ErrorCard(message: error) { vm.startNewRound() }
                            .padding(.top, 6)
                    } else {
                        // 2×4 Grid — full tap area
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnsCount),
                            spacing: gridSpacing
                        ) {
                            ForEach(vm.slots) { slot in
                                Button {
                                    vm.placeCandidate(in: slot.id)
                                } label: {
                                    SlotView(slot: slot)
                                        .frame(width: colWidth, height: slotHeight)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(slot.player != nil || vm.currentCandidate == nil || vm.gameOver)
                                .animation(.spring(duration: 0.3), value: slot.player?.id)
                            }
                        }
                        .frame(maxWidth: maxGridWidth)
                        .padding(.top, 6)

                        // Candidate / Result
                        Group {
                            if let p = vm.currentCandidate, !vm.gameOver {
                                CandidateCard(player: p,
                                              stat: vm.config.stat,
                                              height: cardHeight)
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
                        .frame(maxWidth: 360)
                        .padding(.top, 8)

                        // New Game Button — outline with CT color
                        VStack(spacing: 8) {
                            Button("New Game") { vm.startNewRound() }
                                .buttonStyle(.bordered)
                                .tint(Theme.ctBlue)
                                .foregroundStyle(Theme.ctBlue)
                                .frame(maxWidth: 200)

                            if vm.gameOver {
                                Text("Total: \(format(vm.runningTotal))  •  Goal: \(format(vm.config.goal))")
                                    .font(.footnote)
                                    .bold()
                                    .foregroundStyle(Theme.ctBlue)
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
            .background(Theme.bg) // <— dark CT background
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Helpers

private func format(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

private func colorFor(score: Int, goal: Int) -> Color {
    // Keep result color informative; text color on cards stays CT blue
    let diff = abs(Double(score - goal))
    switch diff {
    case 0..<2_000: return .green
    case 2_000..<10_000: return .orange
    default: return .red
    }
}

// MARK: - Subviews

/// Entire area is tap-target (wrapped by Button in parent).
private struct SlotView: View {
    let slot: Slot

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(slot.player == nil ? Theme.slotStrokeEmpty : Theme.slotStrokeFilled, lineWidth: 2)
                )

            VStack(spacing: 2) {
                Text("× \(slot.multiplier, specifier: "%.1f")")
                    .font(.caption).bold()
                    .foregroundStyle(Theme.ctBlue)

                if let p = slot.player {
                    Text(p.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Theme.ctBlueDim)
                } else {
                    Text("Tap")
                        .font(.caption2)
                        .foregroundStyle(Theme.ctBlueDim)
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
                .foregroundStyle(Theme.ctBlueDim)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 6) {
                Text(player.name)
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(Theme.ctBlue)

                HStack(spacing: 8) {
                    pill("Kills", player.kills)
                    pill("Deaths", player.deaths)
                    pill("Aces", player.acesOrZero)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Theme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func pill(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.caption2).foregroundStyle(Theme.ctBlueDim)
            Text(format(value)).font(.caption).bold().foregroundStyle(Theme.ctBlue)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ResultCard: View {
    let total: Int
    let goal: Int
    let success: Bool
    var body: some View {
        VStack(spacing: 6) {
            Text("Round Complete").font(.headline).foregroundStyle(Theme.ctBlue)
            Text("Total Score: \(format(total))")
                .font(.subheadline).bold()
                .foregroundStyle(Theme.ctBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct EmptyHintCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Ready to place").font(.subheadline).foregroundStyle(Theme.ctBlue)
            Text("Tap a slot to place the highlighted player.")
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 6) {
            Text("Data Error").font(.headline).foregroundStyle(Theme.ctBlue)
            Text(message)
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
                .tint(Theme.ctBlue)
                .foregroundStyle(Theme.ctBlue)
                .frame(maxWidth: 120)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
