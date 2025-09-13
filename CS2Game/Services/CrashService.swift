//
//  CrashService.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import Foundation

/// Absturz-/Fehler-Fassade. Backend: zunächst No-Op.
final class CrashService {
    static let shared = CrashService()

    private var enabled: Bool = UserDefaults.standard.bool(forKey: "settings_crash_enabled")

    private init() {}

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        // Später: Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }

    func recordError(_ error: Error, context: [String: Any]? = nil) {
        guard enabled else { return }
        #if DEBUG
        print("💥 [error] \(error) \(context ?? [:])")
        #endif
        // Später: Crashlytics.crashlytics().record(error: error)
    }

    func log(_ message: String) {
        guard enabled else { return }
        #if DEBUG
        print("💥 [log] \(message)")
        #endif
        // Später: Crashlytics.crashlytics().log(message)
    }
}
