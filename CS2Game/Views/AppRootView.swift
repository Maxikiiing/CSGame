//
//  AppRootView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

/// Zeigt beim Start eine leichte Splash-View, preloaded Daten im Hintergrund
/// und wechselt danach ins eigentliche Menü.
struct AppRootView: View {
    @State private var isReady = false
    @StateObject private var net = NetworkMonitor.shared

    var body: some View {
        ZStack {
            if isReady {
                GameMenuView()
                    .transition(.opacity)
            } else {
                SplashScreen()
                    .transition(.opacity)
            }
        }
        .background(Theme.bg)
        .task {
            await bootstrap()
        }
        .onChange(of: net.isConnected) { _, connected in
            guard connected else { return }
            // Bei Netz-Rückkehr erneut vorladen (idempotent)
            Task {
                async let classic: Void = DataLoader.shared.preload()
                async let rich:    Void = RichDataLoader.shared.preload()
                _ = await (classic, rich)
            }
        }

    }

    /// Preloads ohne den ersten Frame zu blockieren.
    private func bootstrap() async {
        // 1) Dem System minimal Zeit geben, den ersten Frame zu zeichnen
        try? await Task.sleep(nanoseconds: 50_000_000) // 50 ms

        // 2) Preloads parallel starten
        async let classic: Void = DataLoader.shared.preload()     // legacy (falls noch benötigt)
        async let rich:    Void = RichDataLoader.shared.preload() // Rich v2 Remote + Fallback

        // 3) Kurze Mindestdauer, damit Splash nicht „flackert“
        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 s

        // 4) Auf Preloads warten und ins Menü wechseln
        _ = await (classic, rich)

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.25)) {
                isReady = true
            }
        }
    }
}

/// Einfache, leichte Splash-View
private struct SplashScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("CS2 Multiplier")
                .font(.largeTitle).bold()
                .foregroundStyle(Theme.ctBlue)
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading…")
                    .font(.caption)
                    .foregroundStyle(Theme.ctBlueDim)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}
