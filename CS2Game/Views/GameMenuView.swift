//
//  GameMenuView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 01.09.25.
//

import SwiftUI

struct GameMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("CS2 Multiplier")
                    .font(.largeTitle).bold()
                
                Text("Choose a game mode")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    NavigationLink {
                        KillsGameView()
                    } label: {
                        MenuCard(title: "100 000 Kills", subtitle: "Place players to hit the goal", systemImage: "target")
                    }
                    
                    NavigationLink {
                        DeathsGameView()
                    } label: {
                        MenuCard(title: "100 000 Deaths", subtitle: "Place players to hit the goal", systemImage: "skull")
                    }

                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
        }
    }
}

private struct MenuCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
