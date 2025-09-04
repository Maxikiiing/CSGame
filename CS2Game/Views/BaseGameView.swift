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
            // ---- Safe sizing (clamps for 0 / negative / non-finite) ----
            let safeW: CGFloat = (geo.size.width.isFinite && geo.size.width > 0)
                ? geo.size.width
                : UIScreen.main.bounds.width

            let horizPadding: CGFloat = 20
            let gridSpacing: CGFloat = 10
            let columnsCount = 2

            let available = max(0, safeW - 2 * horizPadding)
            // Max grid width, clamped >= 0
            let maxGridWidth = min(available, 340)

            // Column width: handle tiny or zero grid width robustly
            let rawCol = (maxGridWidth - gridSpacing) / 2
            let colWidth = max(80, rawCol.isFinite ? rawCol : 120)

            // Slot height derived from colWidth, but clamped
            let slotHeight = max(48, min(74, colWidth * 0.52))

            // Candidate card height derived from safeW, clamped
            let rawCard = safeW * 0.28
            let cardHeight = max(76, min(110, rawCard.isFinite ? rawCard : 100))

            let achieved = vm.runningTotal >= vm.config.goal
            let barColor = achieved ? Theme.tYellow : Theme.ctBlue
            let barTextColor = achieved ? Theme.tYellow : Theme.ctBlueDim

            ScrollView {
                VStack(alignment: .center, spacing: 14) {
                    Text(vm.config.title)
                        .font(.title).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 6) {
                        Text("Goal: \(format(vm.config.goal))  •  Score: \(format(vm.runningTotal))")
                            .font(.subheadline)
                            .foregroundStyle(barTextColor)

                        ProgressView(value: vm.progress)
                            .tint(barColor)
                            .animation(.easeInOut(duration: 0.5), value: vm.progress)
                            .frame(maxWidth: 260)
                    }

                    if let error = vm.dataError {
                        ErrorCard(message: error) { vm.startNewRound() }
                            .padding(.top, 6)
                    } else {
                        // 2×4 grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnsCount),
                            spacing: gridSpacing
                        ) {
                            ForEach(vm.slots) { slot in
                                Button {
                                    let outcome = vm.placeCandidate(in: slot.id)
                                    switch outcome {
                                    case .placed:    Haptics.tap()
                                    case .completed: Haptics.success()
                                    case .ignored:   break
                                    }
                                } label: {
                                    SlotView(slot: slot)
                                        .frame(
                                            width: colWidth > 0 ? colWidth : 120,
                                            height: slotHeight > 0 ? slotHeight : 60
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(slot.player != nil || vm.currentCandidate == nil || vm.gameOver)
                                .animation(.spring(duration: 0.3), value: slot.player?.id)
                            }
                        }
                        // Wenn maxGridWidth sehr klein (0) wäre, nutze breite Fallbacks
                        .frame(maxWidth: (maxGridWidth > 0 ? maxGridWidth : .infinity))
                        .padding(.top, 6)

                        Group {
                            if let p = vm.currentCandidate, !vm.gameOver {
                                CandidateCard(player: p,
                                              stat: vm.config.stat,
                                              height: cardHeight > 0 ? cardHeight : 90)
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

                        Button {
                            vm.startNewRound()
                        } label: {
                            Text("New Game")
                                .font(.headline)
                                .foregroundStyle(Theme.tYellow)
                                .frame(maxWidth: 220)
                                .padding(.vertical, 10)
                                .background(Theme.tYellowBG)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.tYellowDim, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(Theme.bg)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Subviews

/// Entire area is tap-target (wrapped by Button in parent).
private struct SlotView: View {
    let slot: Slot

    var body: some View {
        let isFilled = (slot.player != nil)

        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFilled ? Theme.slotStrokeFilled : Theme.slotStrokeEmpty, lineWidth: 2)
                )

            VStack(spacing: 2) {
                Text("× \(slot.multiplier, specifier: "%.1f")")
                    .font(.caption).bold()
                    .foregroundStyle(isFilled ? Theme.ctBlue : Theme.tYellow)

                if let p = slot.player {
                    Text(p.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Theme.ctBlue)
                } else {
                    Text("Tap")
                        .font(.caption2)
                        .foregroundStyle(Theme.tYellowDim)
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
        let color = success ? Theme.tYellow : Theme.ctBlue
        VStack(spacing: 6) {
            Text("Round Complete")
                .font(.headline)
                .foregroundStyle(color)
            Text("Total Score: \(format(total))")
                .font(.subheadline)
                .bold()
                .foregroundStyle(color)
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
                .buttonStyle(.plain)
                .foregroundStyle(Theme.ctBlue)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Theme.cardBG)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
