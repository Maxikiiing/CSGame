//
//  WeeklyChallengeBingoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct WeeklyChallengeBingoView: View {
    var body: some View {
        let cfg = BingoConfig(
            title: "Bingo – Weekly Challenge",
            rows: 4,
            cols: 4,
            source: .weekly() // lädt aus bundle "bingo_weekly.json"
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}
