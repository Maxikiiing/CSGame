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
    /// Cache (egal ob remote oder bundle) ist bereit
    static let playersCacheReady = Notification.Name("playersCacheReady")
}

/// Lädt Spielerdaten remote (GitHub Pages) und hält einen In-Memory-Cache.
/// - NICHT blockierend.
/// - Fallback auf Bundle-JSON, falls remote fehlschlägt.
/// - Sendet Notifications über Remote-Status & Cache-Bereitschaft.
final class DataLoader {
    static let shared = DataLoader()

    /// Remote-Quelle (legacy/classic)
    private let remoteURL = URL(string: "https://maxikiiing.github.io/CSData/players_real_data.json")!
    /// Remote-Quelle für Rich v2
    // Achtung: Liegt auf GitPages im Ordner "Bingo" und heißt wie die alte Datei,
    // aber hat das neue RichPlayer-Schema.
    private let remoteURLRichV2 = URL(string: "https://maxikiiing.github.io/CSData/Bingo/players_real_data.json")!

    /// In-Memory-Cache (legacy/classic)
    private var memoryCache: [Player]? = nil
    /// In-Memory-Cache für Rich v2
    private var memoryCacheRich: [RichPlayer]? = nil

    enum RemoteStatus {
        case unknown
        case success
        case failed
    }

    /// Letzter Remote-Status (für initiale Anzeige)
    private(set) var lastRemoteStatus: RemoteStatus = .unknown

    /// Ob irgendein Cache (remote ODER bundle) bereit ist
    var hasCache: Bool { memoryCache != nil || memoryCacheRich != nil }

    private init() {}

    // MARK: - Öffentliche API (legacy)

    /// Asynchroner Preload – beim App-Start/Menu-Start aufrufen.
    /// Holt remote (oder nutzt Bundle als Fallback) und befüllt den In-Memory-Cache.
    func preload() async {
        // 1) Versuche: remote laden
        if let remote = try? await fetchRemote() {
            self.memoryCache = remote
            await postRemoteSuccess()
            await postCacheReady()
            return
        }

        // 2) Remote fehlgeschlagen → Bundle asynchron laden/decoden
        if let bundled = await loadFromBundleAsync() {
            self.memoryCache = bundled
            await postRemoteFailed()
            await postCacheReady()
            return
        }

        // 3) Gar nichts verfügbar (sehr unwahrscheinlich)
        await postRemoteFailed()
    }

    /// Synchrone Abfrage für ViewModels:
    /// - Gibt SOFORT den Memory-Cache zurück, wenn vorhanden (ohne Shuffle).
    /// - Führt KEIN synchrones Decoding auf dem Main-Thread aus.
    /// - Wenn noch kein Cache da ist, triggert Preload im Hintergrund und gibt [] zurück.
    func loadPlayers() -> [Player] {
        if let cached = memoryCache {
            return cached              // unverändert zurückgeben, kein .shuffled()
        }
        // Noch kein Cache? Preload im Hintergrund starten, synchron nichts blockieren
        Task { await self.preload() }
        return []
    }

    // MARK: - Öffentliche API (Rich v2)

    /// Asynchroner Preload für Rich v2 – beim App-Start/Menu-Start aufrufen.
    func preloadRich() async {
        // 1) Versuche: remote laden
        if let remote = try? await fetchRemoteRichV2() {
            self.memoryCacheRich = remote
            await postRemoteSuccess()
            await postCacheReady()
            return
        }
        // 2) Remote fehlgeschlagen → Bundle-Fallback über RichDataLoader (nutzt v2-Datei)
        let bundled = RichDataLoader.shared.loadRichPlayers()
        if !bundled.isEmpty {
            self.memoryCacheRich = bundled
            await postRemoteFailed()
            await postCacheReady()
            return
        }
        // 3) Gar nichts verfügbar
        await postRemoteFailed()
    }

    /// Synchrone Abfrage für ViewModels (Rich v2):
    /// - Gibt SOFORT den Memory-Cache zurück, wenn vorhanden.
    /// - Startet sonst preloadRich() im Hintergrund und gibt [] zurück.
    func loadRichPlayers() -> [RichPlayer] {
        if let cached = memoryCacheRich {
            return cached
        }
        Task { await self.preloadRich() }
        return []
    }

    // MARK: - Remote (legacy)

    private func fetchRemote() async throws -> [Player] {
        var req = URLRequest(url: remoteURL)
        req.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try await Task.detached(priority: .userInitiated) {
            try JSONDecoder().decode([Player].self, from: data)
        }.value
    }


    // MARK: - Remote (Rich v2)

    private func fetchRemoteRichV2() async throws -> [RichPlayer] {
        let (data, response) = try await URLSession.shared.data(from: remoteURLRichV2)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let players = try await Task.detached(priority: .userInitiated) {
            let decoder = JSONDecoder()
            return try decoder.decode([RichPlayer].self, from: data)
        }.value
        print("✅ DataLoader: loaded \(players.count) rich players (v2) from remote.")
        return players
    }

    // MARK: - Bundle Fallback (legacy, asynchron)

    private func loadFromBundleAsync() async -> [Player]? {
        await Task.detached(priority: .utility) { () -> [Player]? in
            guard let url = Bundle.main.url(forResource: "players_real_data", withExtension: "json") else {
                print("❌ DataLoader: players_real_data.json not found in bundle.")
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let players = try decoder.decode([Player].self, from: data)
                print("✅ DataLoader: loaded \(players.count) players from bundle (async).")
                return players
            } catch {
                print("❌ DataLoader: bundle decode error:", error)
                return nil
            }
        }.value
    }

    // MARK: - Notifications

    @MainActor
    private func postRemoteSuccess() {
        lastRemoteStatus = .success
        NotificationCenter.default.post(name: .playersRemoteLoaded, object: nil)
    }

    @MainActor
    private func postRemoteFailed() {
        if lastRemoteStatus != .success {
            lastRemoteStatus = .failed
        }
        NotificationCenter.default.post(name: .playersRemoteFailed, object: nil)
    }

    @MainActor
    private func postCacheReady() {
        NotificationCenter.default.post(name: .playersCacheReady, object: nil)
    }
}
