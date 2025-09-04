//
//  GameMenuView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//
import SwiftUI

/// Main menu that lets the user choose between different game modes.
struct GameMenuView: View {
    @State private var showRemoteWarning: Bool = false
    @State private var canNavigate: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // Title
                Text("CS2 Multiplier")
                    .font(.largeTitle).bold()
                    .foregroundStyle(Theme.ctBlue)

                // Subtitle
                Text("Choose a game mode")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ctBlueDim)

                // Remote failure banner
                if showRemoteWarning {
                    WarningBanner()
                        .transition(.opacity)
                }

                // Loading indicator while preparing cache on first launch
                if !canNavigate {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading players…")
                            .font(.caption)
                            .foregroundStyle(Theme.ctBlueDim)
                    }
                }

                // Menu options
                VStack(spacing: 12) {
                    NavigationLink {
                        KillsGameView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "100 000 Kills", subtitle: "Place players to hit the goal", systemImage: "target")
                    }
                    .disabled(!canNavigate)

                    NavigationLink {
                        DeathsGameView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "100 000 Deaths", subtitle: "Place players to hit the goal", systemImage: "xmark.octagon")
                    }
                    .disabled(!canNavigate)

                    NavigationLink {
                        AcesGameView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "10 000 Aces", subtitle: "Place players to hit the goal", systemImage: "sparkles")
                    }
                    .disabled(!canNavigate)

                    // Bingo Untermenü
                    NavigationLink {
                        BingoMenuView()
                            .toolbarBackground(Theme.bg, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        MenuCard(title: "Bingo", subtitle: "Pick a challenge", systemImage: "square.grid.3x3")
                    }
                    .disabled(!canNavigate)
                }
                .padding(.top, 8)
                .opacity(canNavigate ? 1 : 0.7)

                Spacer()
            }
            .padding()
            .tint(Theme.ctBlue)
            .background(Theme.bg)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // Initial status on appear
            .onAppear {
                showRemoteWarning = (DataLoader.shared.lastRemoteStatus == .failed)
                canNavigate = DataLoader.shared.hasCache
            }
            // React to notifications
            .onReceive(NotificationCenter.default.publisher(for: .playersRemoteFailed)) { _ in
                withAnimation { showRemoteWarning = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: .playersRemoteLoaded)) { _ in
                withAnimation { showRemoteWarning = false }
            }
            .onReceive(NotificationCenter.default.publisher(for: .playersCacheReady)) { _ in
                withAnimation { canNavigate = true }
            }
        }
    }
}

/// Yellow warning in T-theme when remote loading failed
private struct WarningBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.headline)
                .foregroundStyle(Theme.tYellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("Failed to load player data")
                    .font(.subheadline).bold()
                    .foregroundStyle(Theme.tYellow)
                Text("For up-to-date stats, please make sure you are connected to the Internet.")
                    .font(.caption)
                    .foregroundStyle(Theme.tYellow)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Theme.tYellowBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.tYellowDim, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Reusable card used for each menu navigation link.
private struct MenuCard: View {
    let title: String
    let subtitle: String
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
