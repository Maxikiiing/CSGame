//
//  MonthlyChallengeBinoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct MonthlyChallengeBingoView: View {
    var body: some View {
        let cfg = BingoConfig(
            title: "Bingo – Monthly Challenge",
            rows: 4,
            cols: 4,
            source: .monthly() // lädt aus bundle "bingo_monthly.json"
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}
