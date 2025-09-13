//
//  BaseGameView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI

struct BaseGameView: View {
    @StateObject var vm: GameViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geo in
            let safeW: CGFloat = (geo.size.width.isFinite && geo.size.width > 0)
                ? geo.size.width
                : UIScreen.main.bounds.width

            let horizPadding: CGFloat = 20
            let gridSpacing: CGFloat = 10
            let columnsCount = 2

            let available = max(0, safeW - 2 * horizPadding)
            let maxGridWidth = min(available, 340)

            let rawCol = (maxGridWidth - gridSpacing) / 2
            let colWidth = max(80, rawCol.isFinite ? rawCol : 120)

            let slotHeight = max(48, min(74, colWidth * 0.52))

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
                            .frame(maxWidth: 360)                              // max 360 breit
                            .frame(maxWidth: .infinity, alignment: .center)    // in der Mitte
                            .padding(.top, 6)

                    } else {
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
                                    SlotView(slot: slot, statKey: vm.config.stat)
                                        .frame(width: colWidth, height: slotHeight)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                // ⬇️ gesperrt: wenn belegt, kein Kandidat, Game over, Spin aktiv ODER Post-Spin-Lock
                                .disabled(slot.player != nil
                                          || vm.currentCandidate == nil
                                          || vm.gameOver
                                          || vm.isSpinning
                                          || vm.isInteractionLocked)
                                .animation(.spring(duration: 0.3), value: slot.player?.id)
                            }
                        }
                        .frame(maxWidth: maxGridWidth > 0 ? maxGridWidth : .infinity)
                        .padding(.top, 6)

                        Group {
                            if vm.displayedName != nil || vm.isSpinning {
                                UnifiedNameCard(
                                    name: vm.displayedName,
                                    isSpinning: vm.isSpinning,
                                    height: cardHeight
                                )
                                .transition(.opacity)
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
                        
                        NavigationLink {
                            BaseLeaderboardView(modeKey: vm.modeKey(), title: "Best Scores")
                                .toolbarBackground(Theme.bg, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                        } label: {
                            HStack {
                                Image(systemName: "trophy")
                                Text("Leaderboard")
                                    .font(.headline)
                            }
                            .foregroundStyle(Theme.ctBlue)
                            .frame(maxWidth: 220)
                            .padding(.vertical, 10)
                            .background(Theme.cardBG)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.ctBlue, lineWidth: 1) // immer blauer Rand im CT-Theme
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                vm.appWillResignActive()
            }
        }
        .onDisappear {
            vm.appWillResignActive()
        }

    }
}

// MARK: - Subviews

private struct SlotView: View {
    let slot: Slot
    let statKey: GameStatKey

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
                    let statVal = statKey.value(for: p)
                    Text("(\(format(statVal))) \(p.name)")
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

/// Einheitliche Karte für Spin + finalen Namen
private struct UnifiedNameCard: View {
    let name: String?
    let isSpinning: Bool
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Header oben
            Text(isSpinning ? "Drawing next player…" : "Current Player")
                .font(.footnote)
                .foregroundStyle(Theme.ctBlueDim)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)

            Spacer()

            // Name zentriert
            Text(name ?? " ")
                .font(.headline)
                .bold()
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(isSpinning ? Theme.tYellow : Theme.ctBlue)
                .animation(.easeInOut(duration: 0.15), value: isSpinning)

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
