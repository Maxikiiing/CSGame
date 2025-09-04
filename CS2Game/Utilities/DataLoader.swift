//
//  DataLoader.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 29.07.25.
//

import Foundation

extension Notification.Name {
    /// Remote-Players erfolgreich geladen
    static let playersRemoteLoaded = Notification.Name("playersRemoteLoaded")
    /// Remote-Players fehlgeschlagen (Bundle/Fallback verwendet)
    static let playersRemoteFailed = Notification.Name("playersRemoteFailed")
}

/// Lädt Spielerdaten remote (GitHub Pages) und hält einen In-Memory-Cache.
/// - blockiert NICHT die Main-Thread.
/// - Fallback auf Bundle-JSON, falls remote fehlschlägt.
/// - sendet Notifications über den Remote-Ladezustand.
final class DataLoader {
    static let shared = DataLoader()

    /// Remote-Quelle (GitHub Pages, HTTPS/ATS-konform)
    private let remoteURL = URL(string: "https://maxikiiing.github.io/CSData/players_real_data.json")!

    /// In-Memory-Cache (wird beim App-Start / Preload gefüllt)
    private var memoryCache: [Player]? = nil

    enum RemoteStatus {
        case unknown
        case success
        case failed
    }

    /// Letzter Remote-Status (für initiale Anzeige)
    private(set) var lastRemoteStatus: RemoteStatus = .unknown

    private init() {}

    // MARK: - Öffentliche API

    /// Asynchroner Preload – beim App-Start aufrufen.
    /// Holt remote (oder nutzt Bundle als Fallback) und befüllt den In-Memory-Cache.
    func preload() async {
        // Versuche: remote laden
        if let remote = try? await fetchRemote() {
            self.memoryCache = remote
            await postRemoteSuccess()
            return
        }

        // Wenn remote fehlschlägt und Cache noch leer ist: Bundle nutzen
        if self.memoryCache == nil, let bundled = loadFromBundle() {
            self.memoryCache = bundled
        }
        await postRemoteFailed()
    }

    /// Synchrone Abfrage für ViewModels:
    /// - Gibt sofort den Memory-Cache zurück, wenn vorhanden.
    /// - Sonst Bundle (und stößt im Hintergrund einen Preload an).
    /// - Kein Blockieren der UI.
    func loadPlayers() -> [Player] {
        if let cached = memoryCache {
            return cached.shuffled()
        }

        if let bundled = loadFromBundle() {
            // Bundle-Ergebnis direkt nutzen und parallel Remote-Preload anschieben
            self.memoryCache = bundled
            Task { await self.preload() }
            return bundled.shuffled()
        }

        // Nichts lokal vorhanden – Remote asynchron anstoßen
        Task { await self.preload() }
        return []
    }

    // MARK: - Remote

    private func fetchRemote() async throws -> [Player] {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Decode im Hintergrund-Task
        let players = try await Task.detached(priority: .userInitiated) {
            try JSONDecoder().decode([Player].self, from: data)
        }.value

        print("✅ DataLoader: loaded \(players.count) players from remote.")
        return players
    }

    // MARK: - Bundle Fallback

    private func loadFromBundle() -> [Player]? {
        guard let url = Bundle.main.url(forResource: "players_real_data", withExtension: "json") else {
            print("❌ DataLoader: players_real_data.json not found in bundle.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let players = try JSONDecoder().decode([Player].self, from: data)
            print("✅ DataLoader: loaded \(players.count) players from bundle.")
            return players
        } catch {
            print("❌ DataLoader: bundle decode error:", error)
            return nil
        }
    }

    // MARK: - Notifications

    @MainActor
    private func postRemoteSuccess() {
        lastRemoteStatus = .success
        NotificationCenter.default.post(name: .playersRemoteLoaded, object: nil)
    }

    @MainActor
    private func postRemoteFailed() {
        // Nur setzen, wenn wir nicht bereits success hatten
        if lastRemoteStatus != .success {
            lastRemoteStatus = .failed
        }
        NotificationCenter.default.post(name: .playersRemoteFailed, object: nil)
    }
}
