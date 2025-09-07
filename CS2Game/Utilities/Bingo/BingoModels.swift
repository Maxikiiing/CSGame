//
//  BingoModels.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 07.09.25.
//

import Foundation

struct BingoCell: Identifiable, Equatable, Codable {
    let id: UUID
    let condition: BingoCondition
    var player: RichPlayer? = nil

    init(id: UUID = UUID(), condition: BingoCondition, player: RichPlayer? = nil) {
        self.id = id
        self.condition = condition
        self.player = player
    }
}

struct BingoBoardDTO: Codable {
    let title: String
    let rows: Int
    let cols: Int
    let cells: [BingoCondition]
}

enum BingoBoardSource: Equatable {
    case random
    case remote(url: URL)
    case seeded(Int)
    case bundle(resource: String)

    static func weekly(bundleResource: String = "bingo_weekly") -> BingoBoardSource { .bundle(resource: bundleResource) }
    static func monthly(bundleResource: String = "bingo_monthly") -> BingoBoardSource { .bundle(resource: bundleResource) }
}

struct BingoConfig: Equatable {
    let title: String
    let rows: Int
    let cols: Int
    let source: BingoBoardSource
}

enum BingoPlacementOutcome {
    case placed
    case rejected
    case completed
    case ignored
}
