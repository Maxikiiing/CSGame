//
//  KillGameView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//

import SwiftUI

struct KillsGameView: View {
    var body: some View {
        let cfg = GameConfig(
            title: "100 000 Kills",
            goal: 100_000,
            multipliers: [1.0, 0.5, 0.5, 0.2, 0.2, 0.1, 0.1, 0.1], // 2×4 layout
            stat: .kills
        )
        BaseGameView(vm: GameViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}

