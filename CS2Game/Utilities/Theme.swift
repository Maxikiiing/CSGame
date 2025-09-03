//
//  Theme.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI

enum Theme {
    /// Slightly blue-shifted near-black background
    static let bg = Color(red: 0.05, green: 0.07, blue: 0.11)

    /// CT-side light blue (primary text & accent)
    static let ctBlue = Color(red: 0.70, green: 0.85, blue: 1.00)

    /// Dimmed CT blue for secondary text
    static let ctBlueDim = ctBlue.opacity(0.78)

    /// Card/background surfaces on dark
    static let cardBG = Color.white.opacity(0.06)

    /// Slot strokes
    static let slotStrokeEmpty = ctBlue.opacity(0.9)
    static let slotStrokeFilled = Color.white.opacity(0.9)
}
