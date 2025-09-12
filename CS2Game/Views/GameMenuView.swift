//
//  GameMenuView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//
import SwiftUI
import Combine

struct GameMenuView: View {
    // Remote-Status aus dem DataLoader
    @State private var remoteStatus = DataLoader.shared.lastRemoteStatus
    @State private var hasCache     = DataLoader.shared.hasCache

    // Netzwerk-Änderungen beobachten (aus NetworkMonitor.shared)
    @StateObject private var net = NetworkMonitor.shared

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Titel
                    Text("CS2 Multiplier")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Offline/Retry-Banner (nur wenn kein Cache vorhanden und Remote zuletzt fehlgeschlagen)
                    if remoteStatus == .failed && !hasCache {
                        RemoteStatusBanner {
                            Task {
                                async let classic: Void = DataLoader.shared.preload()
                                async let rich:    Void = RichDataLoader.shared.preload()
                                _ = await (classic, rich)
                            }
                        }
                        .transition(.opacity)
                    }

                    // SECTION: Base Modes
                    SectionHeader("Base Modes")
                    VStack(spacing: 12) {
                        NavigationLink {
                            KillsGameView()
                                .toolbarBackground(Theme.bg, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                        } label: {
                            MenuCard(title: "100 000 Kills",
                                     subtitle: "Place players to reach the goal",
                                     systemImage: "target")
                        }

                        NavigationLink {
                            DeathsGameView()
                                .toolbarBackground(Theme.bg, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                        } label: {
                            MenuCard(title: "100 000 Deaths",
                                     subtitle: "Stack the multipliers",
                                     systemImage: "skull")
                        }

                        NavigationLink {
                            AcesGameView()
                                .toolbarBackground(Theme.bg, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                        } label: {
                            MenuCard(title: "10 000 Aces",
                                     subtitle: "Chase massive rounds",
                                     systemImage: "crown")
                        }
                    }

                    // SECTION: Bingo
                    SectionHeader("Bingo")
                    VStack(spacing: 12) {
                        NavigationLink {
                            BingoMenuView()
                                .toolbarBackground(Theme.bg, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                        } label: {
                            MenuCard(title: "Bingo",
                                     subtitle: "Weekly, Monthly & Random Grids",
                                     systemImage: "square.grid.3x3")
                        }
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: 360)
                .padding()
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        // Gear-Button rechts oben → Settings
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                        .toolbarBackground(Theme.bg, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Theme.ctBlue)
                }
            }
        }
        // Netzwerk-Status → erneuter Preload bei Rückkehr des Netzes
        .onChange(of: net.isConnected) { _, connected in
            guard connected else { return }
            Task {
                async let classic: Void = DataLoader.shared.preload()
                async let rich:    Void = RichDataLoader.shared.preload()
                _ = await (classic, rich)
            }
        }
        // DataLoader-Status abhören → Banner ein-/ausblenden
        .onReceive(NotificationCenter.default.publisher(for: .playersRemoteLoaded)) { _ in
            remoteStatus = .success
            hasCache = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .playersRemoteFailed)) { _ in
            // remote fehlgeschlagen – es kann aber bereits ein Bundle-Cache existieren
            remoteStatus = .failed
            hasCache = DataLoader.shared.hasCache
        }
        .onReceive(NotificationCenter.default.publisher(for: .playersCacheReady)) { _ in
            // egal ob remote oder bundle – Cache ist benutzbar → Banner aus
            hasCache = true
        }
    }
}

// MARK: - UI Bausteine (lokal)

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.ctBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.ctBlue, lineWidth: 1) // CT-Theme: blauer Rand
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RemoteStatusBanner: View {
    let retry: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
            VStack(alignment: .leading, spacing: 2) {
                Text("No internet connection")
                    .font(.headline)
                Text("Turn it on and tap Retry to load fresh boards.")
                    .font(.caption)
                    .foregroundStyle(Theme.ctBlueDim)
            }
            Spacer()
            Button("Retry", action: retry)
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.ctBlue, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .foregroundStyle(Theme.ctBlue)
        .padding(10)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
