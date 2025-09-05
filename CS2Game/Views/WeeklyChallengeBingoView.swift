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
            title: "Bingo – Blueprint Test",
            rows: 4,
            cols: 4,
            source: .bundle(resource: "bingo_blueprint_test")
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}
