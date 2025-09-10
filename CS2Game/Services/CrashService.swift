//
//  CrashService.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import Foundation

protocol CrashServicing {
    func record(error: Error, context: [String: Any]?)
    func setUserProperty(_ key: String, value: String?)
}

final class CrashService: CrashServicing {
    static let shared: CrashServicing = CrashService()
    private init() {}
    func record(error: Error, context: [String: Any]? = nil) { /* no-op */ }
    func setUserProperty(_ key: String, value: String?) { /* no-op */ }
}
