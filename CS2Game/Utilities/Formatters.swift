//
//  Formatters.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 03.09.25.
//

import Foundation

/// Centralized number formatter (reused everywhere to avoid repeatedly creating NumberFormatter)
enum Fmt {
    static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
}

/// Format integers with thousands separators, e.g. 12_345 -> "12,345"
public func format(_ n: Int) -> String {
    Fmt.decimal.string(from: NSNumber(value: n)) ?? "\(n)"
}
