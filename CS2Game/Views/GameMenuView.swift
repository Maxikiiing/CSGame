//
//  GameMenuView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//

import SwiftUI

/// Main menu that lets the user choose between different game modes.
struct GameMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title of the application
                Text("CS2 Multiplier")
                    .font(.largeTitle).bold()

                // Subtitle prompting the user to pick a mode
                Text("Choose a game mode")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Menu options for different games
                VStack(spacing: 12) {
                    NavigationLink {
                        // Navigate to kills-based game
                        KillsGameView()
                    } label: {
                        MenuCard(title: "100 000 Kills", subtitle: "Place players to hit the goal", systemImage: "target")
                    }

                    NavigationLink {
                        // Navigate to deaths-based game
                        DeathsGameView()
                    } label: {
                        MenuCard(title: "100 000 Deaths", subtitle: "Place players to hit the goal", systemImage: "skull")
                    }

                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
    }
}

/// Reusable card used for each menu navigation link.
private struct MenuCard: View {
    /// Title displayed in bold on the card.
    let title: String
    /// Subtitle shown beneath the title providing more detail.
    let subtitle: String
    /// System image name displayed on the leading edge of the card.
    let systemImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
