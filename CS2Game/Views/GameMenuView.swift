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
                    .foregroundStyle(Theme.ctBlue)

                // Subtitle prompting the user to pick a mode
                Text("Choose a game mode")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ctBlueDim)

                // Menu options for different games
                VStack(spacing: 12) {
                    NavigationLink {
                        // Navigate to kills-based game
                        KillsGameView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "100 000 Kills", subtitle: "Place players to hit the goal", systemImage: "target")
                    }

                    NavigationLink {
                        // Navigate to deaths-based game
                        DeathsGameView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "100 000 Deaths", subtitle: "Place players to hit the goal", systemImage: "skull")
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .tint(Theme.ctBlue)
            .background(Theme.bg)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                .foregroundStyle(Theme.ctBlue)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.ctBlue)
                Text(subtitle).font(.caption).foregroundStyle(Theme.ctBlueDim)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout)
                .foregroundStyle(Theme.ctBlueDim)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
