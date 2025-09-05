//
//  WeeklyChallengeBingoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct WeeklyChallengeBingoView: View {
    var body: some View {
        let (url, suffix) = Self.weeklyURLAndTitle()
        let cfg = BingoConfig(
            title: "Bingo – Weekly Challenge (\(suffix))",
            rows: 4,
            cols: 4,
            source: .remote(url: url)
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}

private extension WeeklyChallengeBingoView {
    static func weeklyURLAndTitle(
        base: URL = URL(string: "https://maxikiiing.github.io/CSData")!,
        now: Date = Date(),
        timeZone: TimeZone = TimeZone(identifier: "Europe/Berlin")!
    ) -> (URL, String) {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let year = comps.yearForWeekOfYear ?? cal.component(.year, from: now)
        let week = comps.weekOfYear ?? 1
        let ww = String(format: "%02d", week)
        let url = base.appendingPathComponent("bingo/weekly/\(year)-W\(ww).json")
        return (url, "W\(ww) \(year)")
    }
}
