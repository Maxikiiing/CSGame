//
//  BingoCondition.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 07.09.25.
//

import Foundation
import SwiftUI

/// Beschreibt eine Bingo-Bedingung (Slot) inkl. Matching-Logik und UI-Darstellung.
enum BingoCondition: Codable, Equatable {
    // MARK: Fälle
    case min(stat: BingoStatKey, value: Int)
    case max(stat: BingoStatKey, value: Int)
    case range(stat: BingoStatKey, min: Int, max: Int)

    // Attribute
    case nation(Nation)
    case role(Role)
    case teamHistory(Team)
    case ageRange(min: Int, max: Int)
    case rolesAllOf([Role])

    // KD
    case kdMin(Double)
    case kdMax(Double)
    case kdRange(min: Double, max: Double)

    // MARK: Matching
    func matches(_ p: RichPlayer) -> Bool {
        switch self {
        case .min(let stat, let v):
            return stat.value(for: p) >= v
        case .max(let stat, let v):
            return stat.value(for: p) <= v
        case .range(let stat, let lo, let hi):
            let val = stat.value(for: p)
            return val >= lo && val <= hi

        case .nation(let n):
            return p.nation == n
        case .role(let r):
            return p.roles.contains(r)
        case .teamHistory(let t):
            return p.teamHistory.contains(t)
        case .ageRange(let lo, let hi):
            return p.age >= lo && p.age <= hi
        case .rolesAllOf(let roles):
            return roles.allSatisfy { p.roles.contains($0) }

        case .kdMin(let x):
            return p.kd >= x
        case .kdMax(let x):
            return p.kd <= x
        case .kdRange(let lo, let hi):
            return p.kd >= lo && p.kd <= hi
        }
    }

    // MARK: UI – Basistexte (ohne „Role:“/„Roles:“ Präfix)
    var text: String {
        switch self {
        case .min(let stat, let v):            return "≥ \(format(v)) \(stat.displayName)"
        case .max(let stat, let v):            return "≤ \(format(v)) \(stat.displayName)"
        case .range(let stat, let lo, let hi): return "\(format(lo))–\(format(hi)) \(stat.displayName)"
        case .nation(let n):                   return n.displayName
        case .role(let r):                     return r.displayName
        case .teamHistory(let t):              return "Played for: \(t.displayName)"
        case .ageRange(let lo, let hi):        return "Age: \(lo)–\(hi)"
        case .rolesAllOf(let roles):
            let names = roles.map { $0.displayName }.joined(separator: " + ")
            return names
        case .kdMin(let x):                    return String(format: "KD ≥ %.2f", x)
        case .kdMax(let x):                    return String(format: "KD ≤ %.2f", x)
        case .kdRange(let lo, let hi):         return String(format: "KD %.2f–%.2f", lo, hi)
        }
    }

    // MARK: UI – Zwei-Zeilen-Variante für bestimmte Stats
    // Für min/max von: Sniper, Deaths, Kills, Rifle, Grenade.
    // Oben (größer): variabler Teil; unten (klein): Stat-Name.
    var emphasizedTwoLineParts: (primary: String, secondary: String)? {
        switch self {
        case .min(let stat, let v) where Self.isTwoLineStat(stat):
            return ("≥ \(format(v))", stat.displayName)
        case .max(let stat, let v) where Self.isTwoLineStat(stat):
            return ("≤ \(format(v))", stat.displayName)
        default:
            return nil
        }
    }

    private static func isTwoLineStat(_ stat: BingoStatKey) -> Bool {
        switch stat {
        case .sniper, .deaths, .kills, .rifle, .grenade: return true
        default:                                         return false
        }
    }

    // MARK: UI – Inline-Hervorhebung (Basis: Caption2; variable Teile: Footnote Semibold)
    var inlineEmphasizedText: AttributedString {
        var result = AttributedString(text)
        var baseAttr = AttributeContainer(); baseAttr.font = .caption2
        result.setAttributes(baseAttr)

        func emphasize(_ substring: String) {
            if let r = result.range(of: substring) {
                var a = AttributeContainer(); a.font = .footnote.weight(.semibold)
                result[r].setAttributes(a)
            }
        }

        switch self {
        case .min(_, let v):                     emphasize("≥ \(format(v))")
        case .max(_, let v):                     emphasize("≤ \(format(v))")
        case .range(_, let lo, let hi):          emphasize("\(format(lo))–\(format(hi))")
        case .nation(let n):                     emphasize(n.displayName)
        case .role(let r):                       emphasize(r.displayName)
        case .teamHistory(let t):                emphasize(t.displayName)
        case .ageRange(let lo, let hi):          emphasize("\(lo)–\(hi)")
        case .rolesAllOf(let roles):
            let names = roles.map { $0.displayName }.joined(separator: " + ")
            emphasize(names)
        case .kdMin(let x):                      emphasize(String(format: "≥ %.2f", x))
        case .kdMax(let x):                      emphasize(String(format: "≤ %.2f", x))
        case .kdRange(let lo, let hi):           emphasize(String(format: "%.2f–%.2f", lo, hi))
        }

        return result
    }

    // Übergangs-Alias, falls irgendwo noch alter Code `.attributedText` nutzt
    @available(*, deprecated, message: "Use inlineEmphasizedText instead")
    var attributedText: AttributedString { inlineEmphasizedText }

    // MARK: UI – Nationen-Helfer
    var isNationSlot: Bool {
        if case .nation = self { return true }
        return false
    }
    var nationFlag: String? {
        if case .nation(let n) = self { return n.flagEmoji }
        return nil
    }

    // MARK: Codable
    private enum CodingKeys: String, CodingKey { case kind, stat, value, min, max, nation, role, team, roles }
    private enum Kind: String, Codable {
        case min, max, range
        case nation, role, teamHistory, ageRange
        case rolesAllOf
        case kdMin, kdMax, kdRange
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .min:
            self = .min(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                        value: try c.decode(Int.self, forKey: .value))
        case .max:
            self = .max(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                        value: try c.decode(Int.self, forKey: .value))
        case .range:
            self = .range(stat: try c.decode(BingoStatKey.self, forKey: .stat),
                          min: try c.decode(Int.self, forKey: .min),
                          max: try c.decode(Int.self, forKey: .max))
        case .nation:
            self = .nation(try c.decode(Nation.self, forKey: .nation))
        case .role:
            self = .role(try c.decode(Role.self, forKey: .role))
        case .teamHistory:
            self = .teamHistory(try c.decode(Team.self, forKey: .team))
        case .ageRange:
            self = .ageRange(min: try c.decode(Int.self, forKey: .min),
                             max: try c.decode(Int.self, forKey: .max))
        case .rolesAllOf:
            self = .rolesAllOf(try c.decode([Role].self, forKey: .roles))
        case .kdMin:
            self = .kdMin(try c.decode(Double.self, forKey: .value))
        case .kdMax:
            self = .kdMax(try c.decode(Double.self, forKey: .value))
        case .kdRange:
            self = .kdRange(min: try c.decode(Double.self, forKey: .min),
                            max: try c.decode(Double.self, forKey: .max))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .min(let s, let v):
            try c.encode(Kind.min, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(v, forKey: .value)
        case .max(let s, let v):
            try c.encode(Kind.max, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(v, forKey: .value)
        case .range(let s, let lo, let hi):
            try c.encode(Kind.range, forKey: .kind)
            try c.encode(s, forKey: .stat)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)
        case .nation(let n):
            try c.encode(Kind.nation, forKey: .kind)
            try c.encode(n, forKey: .nation)
        case .role(let r):
            try c.encode(Kind.role, forKey: .kind)
            try c.encode(r, forKey: .role)
        case .teamHistory(let t):
            try c.encode(Kind.teamHistory, forKey: .kind)
            try c.encode(t, forKey: .team)
        case .ageRange(let lo, let hi):
            try c.encode(Kind.ageRange, forKey: .kind)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)
        case .rolesAllOf(let roles):
            try c.encode(Kind.rolesAllOf, forKey: .kind)
            try c.encode(roles, forKey: .roles)
        case .kdMin(let x):
            try c.encode(Kind.kdMin, forKey: .kind)
            try c.encode(x, forKey: .value)
        case .kdMax(let x):
            try c.encode(Kind.kdMax, forKey: .kind)
            try c.encode(x, forKey: .value)
        case .kdRange(let lo, let hi):
            try c.encode(Kind.kdRange, forKey: .kind)
            try c.encode(lo, forKey: .min)
            try c.encode(hi, forKey: .max)
        }
    }
}
