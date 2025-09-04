//
//  Haptics.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import UIKit

enum Haptics {
    /// Normal placement: medium impact (spürbarer als light).
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred(intensity: 1.0)
    }

    /// Stronger tap (falls du an anderer Stelle brauchst).
    static func tapStrong() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred(intensity: 1.0)
    }

    /// Success: Kombination aus success notification + heavy impact.
    static func success() {
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.success)

        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        heavy.impactOccurred(intensity: 1.0)
    }
}

