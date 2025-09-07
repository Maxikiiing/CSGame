//
//  MonthlyChallengeBingoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 05.09.25.
//

import SwiftUI

struct MonthlyChallengeBingoView: View {
    var body: some View {
        let (url, suffix) = Self.monthlyURLAndTitle()
        let cfg = BingoConfig(
            title: "Bingo – Monthly Challenge (\(suffix))",
            rows: 3,
            cols: 4,
            source: .remote(url: url)
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}

private extension MonthlyChallengeBingoView {
    static func monthlyURLAndTitle(
        base: URL = URL(string: "https://maxikiiing.github.io/CSData")!,
        now: Date = Date(),
        timeZone: TimeZone = TimeZone(identifier: "Europe/Berlin")!
    ) -> (URL, String) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        let mm = String(format: "%02d", m)
        let url = base.appendingPathComponent("bingo/monthly/\(y)-\(mm).json")

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = timeZone
        let monthName = df.monthSymbols[m - 1]
        return (url, "\(monthName) \(y)")
    }
}
