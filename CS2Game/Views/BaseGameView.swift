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
            let H = geo.size.height
            let isCompactH = H < 700
            let isNarrowW  = W < 370

            // Dynamische Metriken
            let headerTopPadding: CGFloat = isCompactH ? 8 : 16
            let gridSpacing: CGFloat = isCompactH ? 8 : 12
            let colCount = isNarrowW ? 3 : 4   // auf SE ggf. 3 Spalten, sonst 4
            let slotHeight: CGFloat = clamp(isCompactH ? 56 : 76, 52, 96)
            let titleSize: CGFloat = isCompactH ? 24 : 32
            let subSize: CGFloat = isCompactH ? 12 : 15
            let buttonControl: ControlSize = isCompactH ? .small : .regular
            let cardHeight: CGFloat = clamp(H * 0.18, 90, 150) // „CS-Pro“-Karte
            let footerHeight: CGFloat = isCompactH ? 52 : 60

            VStack(spacing: 0) {
                // HEADER
                VStack(spacing: 6) {
                    Text(vm.config.title)
                        .font(.system(size: titleSize, weight: .bold))
                    Text("Goal: \(format(vm.config.goal))  •  Score: \(format(vm.runningTotal))")
                        .font(.system(size: subSize))
                        .foregroundStyle(.secondary)
                    ProgressView(value: vm.progress)
                        .tint(vm.runningTotal >= vm.config.goal ? Color(red: 0.75, green: 0.6, blue: 0.0) : .blue)
                        .frame(maxWidth: 560)
                        .animation(.easeInOut(duration: 0.5), value: vm.progress)
                }
                .padding(.top, headerTopPadding)
                .padding(.horizontal, 16)

                // CONTENT
                if let error = vm.dataError {
                    ErrorCard(message: error) { vm.startNewRound() }
                        .padding(16)
                } else {
                    // GRID (ohne Scrollen, aber komprimiert)
                    let columns = Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: colCount)
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(vm.slots) { slot in
                            SlotView(slot: slot, slotHeight: slotHeight, subSize: subSize)
                                .contentShape(Rectangle())
                                .onTapGesture { vm.placeCandidate(in: slot.id) }
                                .disabled(slot.player != nil || vm.currentCandidate == nil || vm.gameOver)
                                .animation(.spring(duration: 0.35), value: slot.player?.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // CANDIDATE / RESULT
                    Group {
                        if let p = vm.currentCandidate, !vm.gameOver {
                            CandidateCard(player: p,
                                          stat: vm.config.stat,
                                          height: cardHeight,
                                          subSize: subSize)
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
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                Spacer(minLength: 8)

                // FOOTER – fix hinterlegt, skalierte Buttons
                HStack {
                    Button("New Game") { vm.startNewRound() }
                        .controlSize(buttonControl)
                        .buttonStyle(.borderedProminent)

                    if vm.gameOver {
                        Text("Total: \(format(vm.runningTotal))  •  Goal: \(format(vm.config.goal))")
                            .font(.system(size: subSize, weight: .semibold))
                            .foregroundStyle(colorFor(score: vm.runningTotal, goal: vm.config.goal))
                            .padding(.leading, 8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(height: footerHeight)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(edges: .bottom) // Material-Bar darf in der Safe Area sitzen
        }
    }
}

// MARK: - Building Blocks (angepasst für variable Größen)

private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { max(lo, min(v, hi)) }

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

private struct SlotView: View {
    let slot: Slot
    let slotHeight: CGFloat
    let subSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(slot.player == nil ? Color.blue : Color.green,
                        style: StrokeStyle(lineWidth: 2, dash: [6,6]))
                .frame(height: slotHeight)

            VStack(spacing: 4) {
                Text("× \(slot.multiplier, specifier: "%.1f")")
                    .font(.system(size: subSize, weight: .semibold))
                if let p = slot.player {
                    Text(p.name)
                        .font(.system(size: subSize - 1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Tap to place")
                        .font(.system(size: subSize - 2))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
        }
    }
}

private struct CandidateCard: View {
    let player: Player
    let stat: GameStatKey
    let height: CGFloat
    let subSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Text("Current Player")
                .font(.system(size: subSize - 1))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(player.name)
                        .font(.system(size: subSize + 6, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    HStack(spacing: 12) {
                        pill("Kills", player.kills, subSize)
                        pill("Deaths", player.deaths, subSize)
                        pill("Aces", player.acesOrZero, subSize)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Pick a multiplier slot above.")
                .font(.system(size: subSize - 2))
                .foregroundStyle(.secondary)
        }
    }

    private func pill(_ title: String, _ value: Int, _ subSize: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: subSize - 3)).foregroundStyle(.secondary)
            Text(format(value)).font(.system(size: subSize - 1, weight: .semibold))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ResultCard: View {
    let total: Int
    let goal: Int
    let success: Bool
    var body: some View {
        VStack(spacing: 10) {
            Text("Round Complete").font(.headline)
            Text("Total Score: \(format(total))")
                .font(.title3).bold()
                .foregroundStyle(success ? .green : colorFor(score: total, goal: goal))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyHintCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Ready to place").font(.headline)
            Text("Tap a slot to place the highlighted player.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Text("Data Error").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
