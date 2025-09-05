//
//  Theme.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import SwiftUI

enum Theme {
    // Background: slightly blue-shifted near-black
    static let bg = Color(red: 0.05, green: 0.07, blue: 0.11)

    // CT-side (light blue)
    static let ctBlue = Color(red: 0.70, green: 0.85, blue: 1.00)
    static let ctBlueDim = ctBlue.opacity(0.78)

    // T-side (dark yellow / goldish)
    // Slightly darker/warmer gold, readable on dark backgrounds
    static let tYellow = Color(red: 0.92, green: 0.78, blue: 0.22)
    static let tYellowDim = tYellow.opacity(0.85)
    static let tYellowBG = Color(red: 0.92, green: 0.78, blue: 0.22).opacity(0.14) // translucent fill

    // Cards & surfaces on dark
    static let cardBG = Color.white.opacity(0.06)

    // Slot strokes (dynamic in view, but defaults here)
    static let slotStrokeEmpty = tYellowDim        // empty = T
    static let slotStrokeFilled = ctBlue.opacity(0.9) // filled = CT
}
