//
//  RandomGridBingoView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct RandomGridBingoView: View {
    @State private var gridSize: Int = 4   // 3 oder 4

    private func makeVM() -> BingoViewModel {
        let cfg = BingoConfig(
            title: "Bingo – Random Grid",
            rows: gridSize,
            cols: gridSize,
            source: .random
        )
        return BingoViewModel(config: cfg)
    }

    var body: some View {
        BingoBaseView(vm: makeVM()) {
            // Dieser Footer erscheint direkt UNTER dem Leaderboard-Button
            GridSizePicker(gridSize: $gridSize)
        }
        // Wichtig: erzwingt Neuaufbau des StateObject bei Größenwechsel
        .id(gridSize)
        .background(Theme.bg)
        .tint(Theme.ctBlue)
    }

}
private struct GridSizePicker: View {
    @Binding var gridSize: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3")
                Text("Grid Size")
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(Theme.ctBlue)

            HStack(spacing: 10) {
                SelectableSizeButton(
                    title: "3×3",
                    isSelected: gridSize == 3
                ) { gridSize = 3 }

                SelectableSizeButton(
                    title: "4×4",
                    isSelected: gridSize == 4
                ) { gridSize = 4 }
            }

        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SelectableSizeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Theme.tYellow : Theme.ctBlue)
                .background(isSelected ? Theme.tYellowBG : Theme.cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Theme.tYellowDim : Theme.ctBlue, lineWidth: 2)
                )

                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
