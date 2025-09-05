//
//  RandomGridBingoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct RandomGridBingoView: View {
    var body: some View {
        let cfg = BingoConfig(
            title: "Bingo – Random Grid",
            rows: 4,
            cols: 4,
            source: .random
        )
        BingoBaseView(vm: BingoViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}
