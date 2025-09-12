//
//  BingoLoader.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import Foundation

/// Lädt Bingo-Boards (JSON) von Remote ODER lokal aus dem App-Bundle.
/// JSON-Schema (BingoBoardDTO):
/// {
///   "title": "Bingo – Weekly",
///   "rows": 4, "cols": 4,
///   "cells": [
///     { "kind":"min", "stat":"kills", "value":40000 },
///     { "kind":"range", "stat":"aces", "min":100, "max":200 },
///     ...
///   ]
/// }
final class BingoLoader {
    static let shared = BingoLoader()
    private init() {}

    // Remote
    func fetchBoard(from url: URL) async -> BingoBoardDTO? {
        do {
            var req = URLRequest(url: url)
            req.timeoutInterval = 12 // defensiver Timeout
            let (data, response) = try await URLSession.shared.data(for: req)

            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            // Optional: simple Size-Grenze (1 MB)
            guard data.count <= 1_000_000 else { return nil }

            let dto = try JSONDecoder().decode(BingoBoardDTO.self, from: data)
            return dto
        } catch is CancellationError {
            // Task wurde abgebrochen (z. B. View weg) → still
            return nil
        } catch {
            print("❌ BingoLoader: error fetching \(url):", error)
            return nil
        }
    }


    // Lokal (Bundle)
    func loadLocal(named resource: String) -> BingoBoardDTO? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            print("❌ BingoLoader: resource \(resource).json not found in bundle.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let dto = try JSONDecoder().decode(BingoBoardDTO.self, from: data)
            return dto
        } catch {
            print("❌ BingoLoader: decode error for \(resource).json:", error)
            return nil
        }
    }
}
