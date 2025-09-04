//
//  BingoMenuView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import SwiftUI

struct BingoMenuView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Bingo")
                .font(.largeTitle).bold()
                .foregroundStyle(Theme.ctBlue)

            // Subtitle
            Text("Choose a challenge")
                .font(.subheadline)
                .foregroundStyle(Theme.ctBlueDim)

            VStack(spacing: 12) {
                NavigationLink {
                    RandomGridBingoView()
                        .toolbarBackground(Theme.bg, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                } label: {
                    MenuCard(title: "Random Grid", subtitle: "Fresh randomized board", systemImage: "die.face.5")
                }

                NavigationLink {
                    WeeklyChallengeBingoView()
                        .toolbarBackground(Theme.bg, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                } label: {
                    MenuCard(title: "Weekly Challenge", subtitle: "New board every week", systemImage: "calendar")
                }

                NavigationLink {
                    MonthlyChallengeBingoView()
                        .toolbarBackground(Theme.bg, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                } label: {
                    MenuCard(title: "Monthly Challenge", subtitle: "Long-run challenge", systemImage: "calendar.circle")
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .tint(Theme.ctBlue)
        .background(Theme.bg)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// lokaler Menü-Card-Reuse
private struct MenuCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Theme.ctBlue)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.ctBlue)
                Text(subtitle).font(.caption).foregroundStyle(Theme.ctBlueDim)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout)
                .foregroundStyle(Theme.ctBlueDim)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
