//
//  BingoBaseView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

/// Basis-View für alle Bingo-Varianten. Die einzelnen Modi liefern nur die Config.
struct BingoBaseView: View {
    @StateObject var vm: BingoViewModel

    var body: some View {
        GeometryReader { geo in
            let metrics = LayoutMetrics(geo: geo, rows: vm.config.rows, cols: vm.config.cols)

            ScrollView {
                VStack(spacing: 14) {
                    HeaderSection(title: vm.config.title)

                    // Progress + Timer nebeneinander (NEU)
                    ProgressWithTimerSection(
                        filled: vm.cells.filter { $0.player != nil }.count,
                        total: vm.cells.count,
                        elapsed: vm.elapsed,
                        isRunning: vm.isTimerRunning
                    )

                    BoardGridSection(vm: vm, metrics: metrics)

                    NameCardSection(name: vm.displayedName,
                                    isSpinning: vm.isSpinning,
                                    height: metrics.cardHeight)

                    ControlsSection(
                        onNewBoard: { vm.startNewBoard() },
                        onNewPlayer: { vm.rerollCandidate() },
                        isNewPlayerEnabled: vm.canReroll,
                        // Leaderboard (NEU)
                        modeKey: vm.modeKey(),
                        modeTitle: vm.config.title
                    )
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.bg)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Layout Metrics

private struct LayoutMetrics {
    let safeW: CGFloat
    let boardMaxWidth: CGFloat
    let cols: Int
    let rows: Int
    let spacing: CGFloat
    let cellSize: CGSize
    let cardHeight: CGFloat

    init(geo: GeometryProxy, rows: Int, cols: Int) {
        let width = (geo.size.width.isFinite && geo.size.width > 0)
            ? geo.size.width
            : UIScreen.main.bounds.width
        self.safeW = width

        let horizPadding: CGFloat = 20
        let available: CGFloat = max(0, width - 2 * horizPadding)
        self.boardMaxWidth = min(available, 360)

        self.cols = max(1, cols)
        self.rows = max(1, rows)
        self.spacing = 8

        let cellW = (boardMaxWidth - CGFloat(self.cols - 1) * self.spacing) / CGFloat(self.cols)
        self.cellSize = CGSize(width: max(44, cellW), height: max(44, cellW))

        let rawCard = width * 0.28
        self.cardHeight = max(76, min(110, rawCard.isFinite ? rawCard : 100))
    }
}

// MARK: - Sections

private struct HeaderSection: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title).bold()
            .foregroundStyle(Theme.ctBlue)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// NEU: Progress + Timer
private struct ProgressWithTimerSection: View {
    let filled: Int
    let total: Int
    let elapsed: TimeInterval
    let isRunning: Bool

    var body: some View {
        HStack {
            Text("Filled: \(filled) / \(total)")
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
                .padding(.leading, 6) // „etwas nach rechts verschoben“

            Spacer(minLength: 8)

            Text(timerString(elapsed, running: isRunning))
                .font(.caption).monospacedDigit()
                .foregroundStyle(isRunning ? Theme.tYellow : Theme.ctBlue)
        }
        .frame(maxWidth: 360)
    }

    private func timerString(_ t: TimeInterval, running: Bool) -> String {
        let totalMs = Int((t * 100).rounded())
        let minutes = totalMs / 6000
        let seconds = (totalMs % 6000) / 100
        let hundredth = totalMs % 100
        let base = String(format: "%02d:%02d.%02d", minutes, seconds, hundredth)
        return running ? "⏱ \(base)" : "⏲︎ \(base)"
    }
}

private struct BoardGridSection: View {
    @ObservedObject var vm: BingoViewModel
    let metrics: LayoutMetrics

    var body: some View {
        let columns: [GridItem] = Array(
            repeating: GridItem(.fixed(metrics.cellSize.width), spacing: metrics.spacing),
            count: metrics.cols
        )

        return LazyVGrid(columns: columns, spacing: metrics.spacing) {
            ForEach(vm.cells) { cell in
                Button {
                    let outcome = vm.placeCandidate(in: cell.id)
                    switch outcome {
                    case .placed:
                        Haptics.tap()
                    case .completed:
                        Haptics.success()
                    case .rejected:
                        Haptics.error()
                    case .ignored:
                        break
                    }
                } label: {
                    BingoCellView(cell: cell, size: metrics.cellSize)
                }
                .buttonStyle(.plain)
                .disabled(cell.player != nil
                          || vm.currentCandidate == nil
                          || vm.isSpinning
                          || vm.isInteractionLocked
                          || vm.gameOver)
            }
        }
        .frame(width: metrics.boardMaxWidth)
        .padding(.top, 6)
    }
}

private struct NameCardSection: View {
    let name: String?
    let isSpinning: Bool
    let height: CGFloat

    var body: some View {
        Group {
            if name != nil || isSpinning {
                UnifiedNameCard(name: name, isSpinning: isSpinning, height: height)
                    .transition(.opacity)
            } else {
                EmptyHintCard()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: 360)
        .padding(.top, 8)
    }
}

private struct ControlsSection: View {
    let onNewBoard: () -> Void
    let onNewPlayer: () -> Void
    let isNewPlayerEnabled: Bool

    // NEU: Leaderboard Navigation
    let modeKey: String
    let modeTitle: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onNewBoard) {
                    Text("New Board")
                        .font(.headline)
                        .foregroundStyle(Theme.tYellow)
                        .frame(maxWidth: 160)
                        .padding(.vertical, 10)
                        .background(Theme.tYellowBG)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.tYellowDim, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: onNewPlayer) {
                    Text("New Player")
                        .font(.headline)
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: 160)
                        .padding(.vertical, 10)
                        .background(Theme.cardBG)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.slotStrokeEmpty, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(!isNewPlayerEnabled)

                Spacer()
            }
            .frame(maxWidth: 360)

            // Leaderboard Button unten (NEU)
            NavigationLink {
                BingoLeaderboardView(modeKey: modeKey, title: "Best Tries")
                    .toolbarBackground(Theme.bg, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            } label: {
                HStack {
                    Image(systemName: "trophy")
                    Text("Leaderboard")
                        .font(.headline)
                }
                .foregroundStyle(Theme.ctBlue)
                .frame(maxWidth: 360)
                .padding(.vertical, 10)
                .background(Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.slotStrokeEmpty, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 360)
    }
}

// MARK: - Cell & Shared Cards (unverändert)

private struct BingoCellView: View {
    let cell: BingoCell
    let size: CGSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cell.player == nil ? Theme.slotStrokeEmpty : Theme.slotStrokeFilled, lineWidth: 2)
                )

            VStack(spacing: 6) {
                if let p = cell.player {
                    Text(p.name)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(Theme.ctBlue)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 6)
                } else {
                    Text(cell.condition.text)
                        .font(.caption2)
                        .foregroundStyle(Theme.ctBlueDim)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct UnifiedNameCard: View {
    let name: String?
    let isSpinning: Bool
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text(isSpinning ? "Drawing next player…" : "Current Player")
                .font(.footnote)
                .foregroundStyle(Theme.ctBlueDim)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 6)

            Spacer()

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

private struct EmptyHintCard: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Ready to place").font(.subheadline).foregroundStyle(Theme.ctBlue)
            Text("Tap a slot that matches the player.")
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
