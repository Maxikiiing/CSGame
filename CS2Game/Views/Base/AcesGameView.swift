//
//  AcesGameView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI

struct AcesGameView: View {
    var body: some View {
        let cfg = GameConfig(
            title: "10 000 Aces",
            goal: 10_000,
            multipliers: [50, 30, 20, 20, 10, 10, 5, 5],
            stat: .aces
        )
        BaseGameView(vm: GameViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}

