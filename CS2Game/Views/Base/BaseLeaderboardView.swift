//
//  BaseLeaderboardView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

// Views/Base/BaseLeaderboardView.swift
import SwiftUI

struct BaseLeaderboardView: View {
    let modeKey: String
    let title: String

    @State private var entries: [BaseLeaderboardEntry] = []

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Text(title)
                        .font(.title3).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if entries.isEmpty {
                        EmptyStateCard(
                            message: "No results yet",
                            hint: "Finish a round to record your best score."
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(entries) { e in
                                Row(entry: e)
                            }
                        }
                    }
                }
                .frame(maxWidth: 360)
                .padding()
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            entries = BaseLeaderboard.shared.top(modeKey: modeKey, limit: 5)
        }
    }
}

private struct Row: View {
    let entry: BaseLeaderboardEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(format(entry.score))
                    .font(.headline)
                    .foregroundStyle(Theme.ctBlue)
                Text(dateString(entry.finishedAt))
                    .font(.caption)
                    .foregroundStyle(Theme.ctBlueDim)
            }
            Spacer()
        }
        .padding(10)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
