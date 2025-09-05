//
//  RichDataLoader.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import Foundation

/// Separater Loader für erweiterte Bingo-/Slot-Daten.
/// Greift NICHT in deinen bestehenden DataLoader/Player ein.
final class RichDataLoader {
    static let shared = RichDataLoader()

    /// Reihenfolge der bevorzugten Ressourcen-Namen (ohne/mit .json erlaubt).
    private var resourceCandidates: [String] = [
        "players_real_data_v2",
        "bingo_players"
    ]

    private var memoryCache: [RichPlayer]?
    private init() {}

    /// Optional: bevorzugten Ressourcennamen programmatisch setzen (vor preload() aufrufen).
    func configurePreferredResource(_ name: String) {
        let base = (name as NSString).deletingPathExtension
        resourceCandidates.removeAll { ($0 as NSString).deletingPathExtension == base }
        resourceCandidates.insert(base, at: 0)
    }

    /// Synchrone Abfrage für ViewModels (Bingo).
    /// - Gibt sofort den Memory-Cache zurück (falls vorhanden).
    /// - Versucht Kandidaten nacheinander aus dem Bundle zu laden.
    func loadRichPlayers() -> [RichPlayer] {
        if let cache = memoryCache { return cache }

        for candidate in resourceCandidates {
            if let arr = load(fromBundleResourceNamed: candidate), !arr.isEmpty {
                self.memoryCache = arr
                print("✅ RichDataLoader: loaded \(arr.count) rich players from \(candidate).json")
                return arr
            }
        }

        print("❌ RichDataLoader: none of the candidate JSON files found/decoded: \(resourceCandidates.map { "\($0).json" }.joined(separator: ", "))")
        return []
    }

    /// Optional: Asynchroner Preload (z. B. im AppRootView).
    func preload() async { _ = loadRichPlayers() }

    // MARK: - Intern

    private func load(fromBundleResourceNamed name: String) -> [RichPlayer]? {
        guard let url = urlForResource(name) else {
            print("ℹ️ RichDataLoader: \(name).json not in bundle (or not in target membership).")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let arr = try JSONDecoder().decode([RichPlayer].self, from: data)
            return arr
        } catch {
            diagnoseJSON(at: url, fallbackError: error)
            return nil
        }
    }

    private func urlForResource(_ nameOrWithExt: String) -> URL? {
        let ns = nameOrWithExt as NSString
        let base = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? "json" : ns.pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext)
    }

    /// Versucht, bei JSON-Fehlern eine genaue Stelle (Zeile/Spalte) mit Kontext auszugeben.
    private func diagnoseJSON(at url: URL, fallbackError: Error) {
        guard let data = try? Data(contentsOf: url) else {
            print("❌ RichDataLoader: unable to read data for \(url.lastPathComponent)")
            print("Underlying: \(fallbackError)")
            return
        }

        // 1) Syntax-Check mit Foundation, um bei Bedarf NSJSONSerializationErrorIndex zu bekommen
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
            // JSON ist syntaktisch OK → der ursprüngliche Fehler ist ein Decoding-Fehler
            printDecodingError(fallbackError, fileName: url.lastPathComponent)
            return
        } catch let nsErr as NSError {
            let idx = nsErr.userInfo["NSJSONSerializationErrorIndex"] as? Int ?? -1
            if idx >= 0, let text = String(data: data, encoding: .utf8) {
                let (line, col, lineText) = lineAndColumn(forByteOffset: idx, inUTF8Text: text)
                print("❌ RichDataLoader decode error for \(url.lastPathComponent): line \(line), column \(col)")
                print(lineText)
                let caret = String(repeating: " ", count: max(0, col - 1)) + "^"
                print(caret)
                print("Underlying: \(nsErr.localizedDescription)")
                return
            } else {
                print("❌ RichDataLoader decode error for \(url.lastPathComponent): \(nsErr)")
                return
            }
        } catch {
            // Unerwarteter Fehler-Typ beim Syntax-Check
            print("❌ RichDataLoader decode error for \(url.lastPathComponent): \(error)")
            return
        }
    }

    /// Gibt DecodingError lesbar aus (Typ-/Schlüssel-/Wertefehler).
    private func printDecodingError(_ err: Error, fileName: String) {
        func path(_ ctx: DecodingError.Context) -> String {
            let parts = ctx.codingPath.map { $0.stringValue.isEmpty ? "[?]" : $0.stringValue }
            return parts.joined(separator: ".")
        }
        if let e = err as? DecodingError {
            switch e {
            case .typeMismatch(let type, let ctx):
                print("❌ RichDataLoader: type mismatch in \(fileName) at \(path(ctx)) — expected \(type). \(ctx.debugDescription)")
            case .valueNotFound(let type, let ctx):
                print("❌ RichDataLoader: value not found in \(fileName) at \(path(ctx)) — missing \(type). \(ctx.debugDescription)")
            case .keyNotFound(let key, let ctx):
                print("❌ RichDataLoader: key '\(key.stringValue)' not found in \(fileName) at \(path(ctx)). \(ctx.debugDescription)")
            case .dataCorrupted(let ctx):
                print("❌ RichDataLoader: data corrupted in \(fileName) at \(path(ctx)). \(ctx.debugDescription)")
            @unknown default:
                print("❌ RichDataLoader: unknown decoding error in \(fileName): \(e)")
            }
        } else {
            print("❌ RichDataLoader: \(fileName) decoding error: \(err)")
        }
    }

    /// Ermittelt (Zeile, Spalte, Zeilentext) für einen Byte-Offset (UTF-8).
    private func lineAndColumn(forByteOffset idx: Int, inUTF8Text text: String) -> (line: Int, col: Int, lineText: String) {
        let lines = text.components(separatedBy: .newlines)
        var byteCount = 0
        for (i, line) in lines.enumerated() {
            let isLast = (i == lines.count - 1)
            let lineBytes = line.lengthOfBytes(using: .utf8) + (isLast ? 0 : 1) // +1 für '\n' außer in der letzten Zeile
            if idx < byteCount + lineBytes {
                let col = max(1, idx - byteCount + 1)
                return (i + 1, col, line)
            }
            byteCount += lineBytes
        }
        // Fallback
        return (lines.count, 1, lines.last ?? "")
    }
}
