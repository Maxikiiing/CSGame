//
//  LeaderboardView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import SwiftUI

import SwiftUI

struct BingoLeaderboardView: View {
    let modeKey: String
    let title: String

    @State private var entries: [LeaderboardEntry] = []

    var body: some View {
        Group {
            if entries.isEmpty {
                // Kein List-Container → keine weißen Balken
                VStack(spacing: 12) {
                    Text(title)
                        .font(.title3).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    EmptyStateCard(
                        message: "No results yet",
                        hint: "Finish a board to record your best time."
                    )
                }
                .frame(maxWidth: 360)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            } else {
                // Liste mit verstecktem System-Background
                List {
                    Section {
                        ForEach(entries) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(timeString(e.elapsed))
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
                    } header: {
                        Text(title)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)   // <<< weiße Balken weg
                .background(Theme.bg)               // <<< Theme-Background
            }
        }
        .background(Theme.bg)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            entries = BingoLeaderboard.shared.all(modeKey: modeKey)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let totalMs = Int((t * 100).rounded())
        let minutes = totalMs / 6000
        let seconds = (totalMs % 6000) / 100
        let hundredth = totalMs % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredth)
    }

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}

private struct EmptyStateCard: View {
    let message: String
    let hint: String

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.headline)
                .foregroundStyle(Theme.ctBlue)

            Text(hint)
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.slotStrokeEmpty, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
