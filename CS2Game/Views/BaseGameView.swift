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
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 6) {
                Text(vm.config.title)
                    .font(.largeTitle).bold()
                Text("Goal: \(format(vm.config.goal))  •  Score: \(format(vm.runningTotal))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: vm.progress)
                    .tint(vm.runningTotal >= vm.config.goal ? Color(red: 0.75, green: 0.6, blue: 0.0) : .blue)
                    .animation(.easeInOut(duration: 0.5), value: vm.progress)
            }
            
            if let error = vm.dataError {
                ErrorCard(message: error) { vm.startNewRound() }
            } else {
                // Slots Grid
                GridView(items: vm.slots) { slot in
                    SlotView(slot: slot)
                        .contentShape(Rectangle())
                        .onTapGesture { vm.placeCandidate(in: slot.id) }
                        .disabled(slot.player != nil || vm.currentCandidate == nil || vm.gameOver)
                        .animation(.spring(duration: 0.35), value: slot.player?.id)
                }
                
                Divider()
                
                // Candidate / Result
                if let p = vm.currentCandidate, !vm.gameOver {
                    CandidateCard(player: p, stat: vm.config.stat)
                        .transition(.opacity.combined(with: .scale))
                } else if !vm.slots.contains(where: { $0.player == nil }) {
                    ResultCard(total: vm.runningTotal,
                               goal: vm.config.goal,
                               success: vm.hasWon)
                        .transition(.opacity)
                } else {
                    EmptyHintCard()
                }
                
                // Bottom actions
                HStack {
                    Button("New Game") { vm.startNewRound() }
                        .buttonStyle(.borderedProminent)
                    
                    if vm.gameOver {
                        Text("Total: \(format(vm.runningTotal))  •  Goal: \(format(vm.config.goal))")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(colorFor(score: vm.runningTotal, goal: vm.config.goal))
                            .padding(.leading, 8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut(duration: 0.25), value: vm.gameOver)
    }
}

// MARK: - Small UI Blocks

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

private struct GridView<T: Identifiable, Content: View>: View {
    let items: [T]
    let content: (T) -> Content
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { content($0) }
        }
    }
}

private struct SlotView: View {
    let slot: Slot
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(slot.player == nil ? Color.blue : Color.green, style: StrokeStyle(lineWidth: 2, dash: [6,6]))
                .frame(height: 80)
            
            VStack(spacing: 4) {
                Text("× \(slot.multiplier, specifier: "%.1f")")
                    .font(.subheadline).bold()
                if let p = slot.player {
                    Text(p.name).font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Tap to place")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CandidateCard: View {
    let player: Player
    let stat: GameStatKey
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Player").font(.subheadline).foregroundStyle(.secondary)
            VStack(spacing: 6) {
                Text(player.name).font(.title3).bold()
                HStack(spacing: 16) {
                    pill("Kills", player.kills)
                    pill("Deaths", player.deaths)
                    pill("Aces", player.acesOrZero)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Pick a multiplier slot above.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private func pill(_ title: String, _ value: Int) -> some View {
        VStack {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(format(value)).font(.caption).bold()
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
        VStack(spacing: 8) {
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
