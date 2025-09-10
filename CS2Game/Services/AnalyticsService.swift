//
//  AnalyticsService.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import Foundation

protocol AnalyticsServicing {
    func screen(_ name: String)
    func event(_ name: String, params: [String: Any]?)
    func scoreSubmitted(modeKey: String, value: Int)
}

final class AnalyticsService: AnalyticsServicing {
    static let shared: AnalyticsServicing = AnalyticsService()
    private init() {}

    func screen(_ name: String) { /* no-op */ }
    func event(_ name: String, params: [String: Any]? = nil) { /* no-op */ }
    func scoreSubmitted(modeKey: String, value: Int) { /* no-op */ }
}
