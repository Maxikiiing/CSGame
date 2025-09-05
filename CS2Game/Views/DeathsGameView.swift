
import SwiftUI

struct DeathsGameView: View {
    var body: some View {
        let cfg = GameConfig(
            title: "100 000 Deaths",
            goal: 100_000,
            multipliers: [1.0, 0.5, 0.5, 0.5, 0.2, 0.2, 0.1, 0.1], // 2×4 layout
            stat: .deaths
        )
        BaseGameView(vm: GameViewModel(config: cfg))
            .background(Theme.bg)
            .tint(Theme.ctBlue)
    }
}

