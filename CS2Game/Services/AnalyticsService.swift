//
//  AnalyticsService.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import Foundation

/// Protokoll für konkrete Backends (Firebase, TelemetryDeck, …)
protocol AnalyticsSink {
    func setEnabled(_ enabled: Bool)
    func screen(_ name: String, params: [String: Any]?)
    func event(_ name: String, params: [String: Any]?)
    func setUserProperty(_ value: String?, for key: String)
}

/// No-Op Implementierung (default, bis du ein echtes Backend einhängst)
final class NoopAnalyticsSink: AnalyticsSink {
    private var enabled = false
    func setEnabled(_ enabled: Bool) { self.enabled = enabled }
    func screen(_ name: String, params: [String : Any]?) {
        #if DEBUG
        if enabled { print("📊 [screen] \(name) \(params ?? [:])") }
        #endif
    }
    func event(_ name: String, params: [String : Any]?) {
        #if DEBUG
        if enabled { print("📊 [event]  \(name) \(params ?? [:])") }
        #endif
    }
    func setUserProperty(_ value: String?, for key: String) {
        #if DEBUG
        if enabled { print("📊 [user]   \(key)=\(value ?? "nil")") }
        #endif
    }
}

/// Singleton-Fassade. Du ersetzt später nur `sink` (z. B. durch FirebaseSink)
final class AnalyticsService {
    static let shared = AnalyticsService()

    /// Aktives Backend
    private var sink: AnalyticsSink = NoopAnalyticsSink()

    /// Consent-Status (Startzustand aus Settings)
    private var enabled: Bool = UserDefaults.standard.bool(forKey: "settings_analytics_enabled")

    private init() {
        sink.setEnabled(enabled)
    }

    // MARK: - Public API

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        sink.setEnabled(enabled)
    }

    func use(_ newSink: AnalyticsSink) {
        self.sink = newSink
        self.sink.setEnabled(enabled)
    }

    func screen(_ name: String, params: [String: Any]? = nil) {
        guard enabled else { return }
        sink.screen(name, params: params)
    }

    func event(_ name: String, params: [String: Any]? = nil) {
        guard enabled else { return }
        sink.event(name, params: params)
    }

    func setUserProperty(_ value: String?, for key: String) {
        guard enabled else { return }
        sink.setUserProperty(value, for: key)
    }
}
