//
//  LeaderboardView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import SwiftUI

struct BingoLeaderboardView: View {
    let modeKey: String
    let title: String

    @State private var entries: [LeaderboardEntry] = []

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title3).bold()
                .foregroundStyle(Theme.ctBlue)

            if entries.isEmpty {
                Text("No results yet")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ctBlueDim)
                    .padding(.top, 8)
                Spacer()
            } else {
                List {
                    Section(header: Text("Top 5")) {
                        ForEach(entries.prefix(5)) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatElapsed(e.elapsed))
                                        .font(.headline)
                                        .foregroundStyle(Theme.ctBlue)
                                    Text(dateString(e.finishedAt))
                                        .font(.caption)
                                        .foregroundStyle(Theme.ctBlueDim)
                                }
                                Spacer()
                            }
                            .listRowBackground(Theme.cardBG)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
            }

            Spacer()
        }
        .padding()
        .background(Theme.bg)
        .tint(Theme.ctBlue)
        .onAppear {
            entries = BingoLeaderboard.shared.top(modeKey: modeKey, limit: 5)
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func formatElapsed(_ t: TimeInterval) -> String {
        let totalMs = Int((t * 100).rounded()) // Hundertstel
        let minutes = totalMs / 6000
        let seconds = (totalMs % 6000) / 100
        let hundredth = totalMs % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredth)
    }

    private func dateString(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: d)
    }
}
