//
//  LeaderboardView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import SwiftUI

struct BingoLeaderboardView: View {
    let modeKey: String
    let title: String

    @State private var exactTop: [LeaderboardEntry] = []         // Random/sonstige: Top 5 des exakten modeKey
    @State private var currentPeriodTop: [LeaderboardEntry] = [] // Weekly/Monthly: Top 5 der aktuellen Woche/Monat
    @State private var pastPeriodBests: [LeaderboardEntry] = []  // Weekly/Monthly: je vergangener Zeitraum 1 Bestwert
    @State private var isWeeklyOrMonthly = false
    @State private var parsed: ModeKeyParts?

    var body: some View {
        ZStack {
            // Vollflächiger CT-Background (über gesamte View-Hierarchie)
            Theme.bg.ignoresSafeArea()

            ScrollView {
                // Outer-Füllrahmen: nimmt volle Breite der ScrollView ein
                VStack(spacing: 0) {
                    // Dein eigentlicher Inhalt, auf 360 begrenzt,
                    // aber zentriert innerhalb der vollen Breite
                    VStack(spacing: 14) {
                        Text(title)
                            .font(.title3).bold()
                            .foregroundStyle(Theme.ctBlue)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isWeeklyOrMonthly, let parts = parsed {
                            // --- Aktueller Zeitraum (Top 5) ---
                            SectionHeader(text: parts.headerForCurrentSection)
                            if currentPeriodTop.isEmpty {
                                EmptyStateCard(
                                    message: "No results yet for \(parts.periodDisplay)",
                                    hint: "Finish a board to record your best time."
                                )
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(currentPeriodTop) { e in
                                        EntryRow(entry: e)
                                    }
                                }
                            }

                            // --- Vergangenheit (pro Zeitraum 1 Bestwert) ---
                            if !pastPeriodBests.isEmpty {
                                SectionHeader(text: parts.headerForPastSection)
                                VStack(spacing: 8) {
                                    ForEach(pastPeriodBests) { e in
                                        EntryRow(entry: e, showPeriodLeft: true)
                                    }
                                }
                            }
                        } else {
                            // Random / andere Modi: unverändert
                            if exactTop.isEmpty {
                                EmptyStateCard(
                                    message: "No results yet",
                                    hint: "Finish a board to record your best time."
                                )
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(exactTop) { e in EntryRow(entry: e) }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 360)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .top) // <<< nimmt volle Breite ein
                }
            }
            .scrollIndicators(.visible) // optional
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { reload() }
    }


    private func reload() {
        // 1) modeKey analysieren
        let parts = ModeKeyParts.parse(modeKey)
        parsed = parts

        // 2) Branch: weekly/monthly vs. andere
        switch parts?.category {
        case .weekly, .monthly:
            isWeeklyOrMonthly = true

            // Aktuelle Woche/Monat = genau dieser modeKey
            currentPeriodTop = BingoLeaderboard.shared.top(modeKey: modeKey, limit: 5)

            // Vergangenheit: gleiche Kategorie & gleiche Grid-Größe, pro Zeitraum ein Bestwert
            let all = BingoLeaderboard.shared.allEntries()
            let sameCatAndSize = all.filter { entry in
                guard let p = ModeKeyParts.parse(entry.modeKey) else { return false }
                return p.category == parts?.category && p.size == parts?.size
            }

            // Nach Zeitraum gruppieren (z. B. "2025-W36" / "2025-09")
            let grouped = Dictionary(grouping: sameCatAndSize) { entry in
                ModeKeyParts.parse(entry.modeKey)?.period ?? ""
            }

            // Aktuelle Periode aus den Gruppen ausschließen
            let currentPeriodKey = parts?.period ?? ""
            var bestPerPast: [LeaderboardEntry] = []
            for (period, entries) in grouped where period != currentPeriodKey {
                if let best = entries.sorted(by: { $0.elapsed < $1.elapsed }).first {
                    bestPerPast.append(best)
                }
            }

            // Neueste zuerst sortieren (Tokens sind "YYYY-Www" / "YYYY-MM" → lexikographisch ok)
            pastPeriodBests = bestPerPast.sorted { $0.periodToken > $1.periodToken }

        default:
            isWeeklyOrMonthly = false
            exactTop = BingoLeaderboard.shared.top(modeKey: modeKey, limit: 5)
        }
    }
}

// MARK: - Parsing & UI-Helfer

private struct ModeKeyParts {
    enum Category { case weekly, monthly, random, seeded, bundle, remote, other }
    let category: Category
    let period: String?   // z. B. "2025-W36" oder "2025-09"
    let size: String      // z. B. "4x4"

    // Erwartete Formen:
    // "weekly:2025-W36.json|4x4"  → wir entfernen ".json"
    // "monthly:2025-09.json|3x3"  → wir entfernen ".json"
    // "random|4x4", "seeded:XYZ|4x4", "bundle:NAME|4x4", "remote:NAME.json|4x4"
    static func parse(_ key: String) -> ModeKeyParts? {
        let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let left = parts[0]
        let size = parts[1]

        func stripJSON(_ s: String) -> String {
            s.hasSuffix(".json") ? String(s.dropLast(5)) : s
        }

        if left.hasPrefix("weekly:") {
            let token = stripJSON(String(left.dropFirst("weekly:".count)))
            return .init(category: .weekly, period: token, size: size)
        } else if left.hasPrefix("monthly:") {
            let token = stripJSON(String(left.dropFirst("monthly:".count)))
            return .init(category: .monthly, period: token, size: size)
        } else if left == "random" {
            return .init(category: .random, period: nil, size: size)
        } else if left.hasPrefix("seeded:") {
            return .init(category: .seeded, period: String(left.dropFirst("seeded:".count)), size: size)
        } else if left.hasPrefix("bundle:") {
            return .init(category: .bundle, period: String(left.dropFirst("bundle:".count)), size: size)
        } else if left.hasPrefix("remote:") {
            return .init(category: .remote, period: String(left.dropFirst("remote:".count)), size: size)
        } else {
            return .init(category: .other, period: left, size: size)
        }
    }

    var periodDisplay: String { period ?? "-" }

    var headerForCurrentSection: String {
        switch category {
        case .weekly:  return "This Week (\(periodDisplay)) — Top 5"
        case .monthly: return "This Month (\(periodDisplay)) — Top 5"
        default:       return "Top 5"
        }
    }

    var headerForPastSection: String {
        switch category {
        case .weekly:  return "Past Weeks — Best Attempts"
        case .monthly: return "Past Months — Best Attempts"
        default:       return "Past — Best Attempts"
        }
    }
}

// Für Sortierung/Anzeige der Vergangenheit
private extension LeaderboardEntry {
    var periodToken: String {
        let parts = modeKey.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return "" }
        let left = parts[0]
        let token = left.split(separator: ":", maxSplits: 1).map(String.init).last ?? ""
        return token.hasSuffix(".json") ? String(token.dropLast(5)) : token
    }
}

private struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.ctBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

private struct EntryRow: View {
    let entry: LeaderboardEntry
    var showPeriodLeft: Bool = false

    var body: some View {
        HStack {
            if showPeriodLeft {
                Text(entry.periodToken)
                    .font(.caption)
                    .foregroundStyle(Theme.ctBlueDim)
                    .frame(width: 82, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timeString(entry.elapsed))
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

    private func timeString(_ t: TimeInterval) -> String {
        let totalMs = Int((t * 100).rounded())
        let minutes = totalMs / 6000
        let seconds = (totalMs % 6000) / 100
        let hundredth = totalMs % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredth)
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
