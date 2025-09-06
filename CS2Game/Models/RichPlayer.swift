//
//  RichPlayer.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 04.09.25.
//

import Foundation

// MARK: - Helpers

private extension String {
    /// Lowercased + entfernt Leerzeichen/Punkte/Apostrophe/Striche/Unterstriche – gut für Mapping.
    var normalizedKey: String {
        self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
}

// MARK: - Roles

enum Role: Equatable, Codable {
    case IGL
    case Rifler
    case Sniper            // "AWPer"/"AWP" werden hierauf normalisiert
    case other(String)

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw.normalizedKey {
        case "igl":                  self = .IGL
        case "rifler":               self = .Rifler
        case "sniper", "awper", "awp": self = .Sniper
        default:                     self = .other(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .IGL:          try c.encode("IGL")
        case .Rifler:       try c.encode("Rifler")
        case .Sniper:       try c.encode("Sniper")
        case .other(let s): try c.encode(s)
        }
    }
}

// MARK: - Nation

enum Nation: Equatable, Codable {
    // Häufige CS-Länder
    case France, Denmark, Sweden, Finland, Norway, Germany, Poland, Netherlands, Belgium
    case Spain, Portugal, Italy
    case UnitedKingdom, Ireland
    case Ukraine, Russia, Kazakhstan, Lithuania, Latvia, Estonia, Belarus
    case Czechia, Slovakia, Hungary, Romania, Bulgaria, Serbia, Croatia, BosniaAndHerzegovina, Slovenia, Greece, Turkey
    case Israel
    case USA, Canada, Brazil, Argentina, Chile, Mexico
    case Australia, Mongolia
    case other(String)

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw.normalizedKey {
        // Nord-/Westeuropa
        case "france": self = .France
        case "denmark": self = .Denmark
        case "sweden": self = .Sweden
        case "finland": self = .Finland
        case "norway": self = .Norway
        case "germany": self = .Germany
        case "poland": self = .Poland
        case "netherlands", "holland": self = .Netherlands
        case "belgium": self = .Belgium
        case "spain": self = .Spain
        case "portugal": self = .Portugal
        case "italy": self = .Italy
        case "unitedkingdom", "uk", "greatbritain", "england", "scotland", "wales": self = .UnitedKingdom
        case "ireland": self = .Ireland
        // Osteuropa / GUS
        case "ukraine": self = .Ukraine
        case "russia", "russianfederation": self = .Russia
        case "kazakhstan": self = .Kazakhstan
        case "lithuania": self = .Lithuania
        case "latvia": self = .Latvia
        case "estonia": self = .Estonia
        case "belarus": self = .Belarus
        case "czechia", "czechrepublic": self = .Czechia
        case "slovakia": self = .Slovakia
        case "hungary": self = .Hungary
        case "romania": self = .Romania
        case "bulgaria": self = .Bulgaria
        case "serbia": self = .Serbia
        case "croatia": self = .Croatia
        case "bosniaandherzegovina", "bosnia", "bih": self = .BosniaAndHerzegovina
        case "slovenia": self = .Slovenia
        case "greece": self = .Greece
        case "turkey": self = .Turkey
        case "israel": self = .Israel
        // Americas
        case "usa", "unitedstates", "unitedstatesofamerica", "us": self = .USA
        case "canada": self = .Canada
        case "brazil": self = .Brazil
        case "argentina": self = .Argentina
        case "chile": self = .Chile
        case "mexico": self = .Mexico
        // Ozeanien
        case "australia": self = .Australia
        // Asia
        case "mongolia": self = .Mongolia
        default:
            self = .other(raw)

        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(displayName)
    }

    var displayName: String {
        switch self {
        case .France: return "France"
        case .Denmark: return "Denmark"
        case .Sweden: return "Sweden"
        case .Finland: return "Finland"
        case .Norway: return "Norway"
        case .Germany: return "Germany"
        case .Poland: return "Poland"
        case .Netherlands: return "Netherlands"
        case .Belgium: return "Belgium"
        case .Spain: return "Spain"
        case .Portugal: return "Portugal"
        case .Italy: return "Italy"
        case .UnitedKingdom: return "United Kingdom"
        case .Ireland: return "Ireland"
        case .Ukraine: return "Ukraine"
        case .Russia: return "Russia"
        case .Kazakhstan: return "Kazakhstan"
        case .Lithuania: return "Lithuania"
        case .Latvia: return "Latvia"
        case .Estonia: return "Estonia"
        case .Belarus: return "Belarus"
        case .Czechia: return "Czechia"
        case .Slovakia: return "Slovakia"
        case .Hungary: return "Hungary"
        case .Romania: return "Romania"
        case .Bulgaria: return "Bulgaria"
        case .Serbia: return "Serbia"
        case .Croatia: return "Croatia"
        case .BosniaAndHerzegovina: return "Bosnia and Herzegovina"
        case .Slovenia: return "Slovenia"
        case .Greece: return "Greece"
        case .Turkey: return "Turkey"
        case .Israel: return "Israel"
        case .USA: return "United States"
        case .Canada: return "Canada"
        case .Brazil: return "Brazil"
        case .Argentina: return "Argentina"
        case .Chile: return "Chile"
        case .Mexico: return "Mexico"
        case .Australia: return "Australia"
        case .Mongolia: return "Mongolia"
        case .other(let s): return s
        }
    }
}

// MARK: - Team / Organisation

enum Team: Equatable, Codable {
    case G2, NAVI, Vitality, FaZe, Astralis, MOUZ, ENCE, Heroic, Liquid, Cloud9
    case VirtusPro, NIP, Fnatic, FURIA, Complexity, OG, Imperial, Apeks, Falcons, Monte
    case Spirit, BIG, GamerLegion,  NineINE, BNE, Endpoint
    case PARAVISION, AVANGAR, DRILLAS, MADLions, PASSIONUA, Gambit, IntoTheBreach, Epsilon, MovistarRiders, TSM, Titan, LDLC, Luminosity, SK, MIBR, REDCanids, ZeroZeroNation, ATK, Dignitas, Envy, MongolZ
    case VegaSquadron, Nemiga, IHC, Checkmate, HAVU, Nexus, CopenhagenWolves
    case other(String)

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw.normalizedKey {
        case "g2", "g2esports": self = .G2
        case "navi", "natusvincere", "navination", "nav": self = .NAVI
        case "vitality", "teamvitality": self = .Vitality
        case "faze", "fazeclan": self = .FaZe
        case "astralis": self = .Astralis
        case "mouz", "mousesports": self = .MOUZ
        case "ence": self = .ENCE
        case "heroic": self = .Heroic
        case "liquid", "teamliquid": self = .Liquid
        case "cloud9", "c9": self = .Cloud9
        case "virtuspro", "virtusproteam", "virtuspro.","virtus.pro": self = .VirtusPro
        case "nip", "ninjasinpyjamas": self = .NIP
        case "fnatic": self = .Fnatic
        case "furia", "furiaesports": self = .FURIA
        case "complexity", "complexitygaming", "col": self = .Complexity
        case "og": self = .OG
        case "imperial", "imperialesports": self = .Imperial
        case "apeks": self = .Apeks
        case "falcons", "teamfalcons": self = .Falcons
        case "monte", "teammonte": self = .Monte
        case "spirit", "teamspirit": self = .Spirit
        case "big", "bigclan", "berlingaming": self = .BIG
        case "gamerlegion": self = .GamerLegion
        case "9ine", "nine": self = .NineINE
        case "bne", "badnewseagles": self = .BNE
        case "endpoint", "endpointcex": self = .Endpoint
        case "paravision": self = .PARAVISION
        case "avangar": self = .AVANGAR
        case "drillas": self = .DRILLAS
        case "madlions": self = .MADLions
        case "passionua": self = .PASSIONUA
        case "gambit": self = .Gambit
        case "intothebreach": self = .IntoTheBreach
        case "epsilon": self = .Epsilon
        case "movistar riders", "movistarriders": self = .MovistarRiders
        case "tsm", "teamsolomid": self = .TSM
        case "titan" : self = .Titan
        case "ldlc": self = .LDLC
        case "luminosity", "luminositygaming": self = .Luminosity
        case "sk", "skgaming": self = .SK
        case "mibr": self = .MIBR
        case "redcanids": self = .REDCanids
        case "00nation": self = .ZeroZeroNation
        case "atk": self = .ATK
        case "dignitas", "teamdignitas": self = .Dignitas
        case "envy", "envyus", "teamenvyus": self = .Envy
        case "mongolz", "teammongolz": self = .MongolZ
        case "vegasquadron": self = .VegaSquadron
        case "nemiga": self = .Nemiga
        case "ihc": self = .IHC
        case "checkmate": self = .Checkmate
        case "havu": self = .HAVU
        case "nexus": self = .Nexus
        case "copenhagenwolves" : self = .CopenhagenWolves
        default:
            self = .other(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(displayName)
    }

    var displayName: String {
        switch self {
        case .G2: return "G2"
        case .NAVI: return "NAVI"
        case .Vitality: return "Vitality"
        case .FaZe: return "FaZe"
        case .Astralis: return "Astralis"
        case .MOUZ: return "MOUZ"
        case .ENCE: return "ENCE"
        case .Heroic: return "Heroic"
        case .Liquid: return "Liquid"
        case .Cloud9: return "Cloud9"
        case .VirtusPro: return "Virtus.pro"
        case .NIP: return "NIP"
        case .Fnatic: return "Fnatic"
        case .FURIA: return "FURIA"
        case .Complexity: return "Complexity"
        case .OG: return "OG"
        case .Imperial: return "Imperial"
        case .Apeks: return "Apeks"
        case .Falcons: return "Falcons"
        case .Monte: return "Monte"
        case .Spirit: return "Spirit"
        case .BIG: return "BIG"
        case .GamerLegion: return "GamerLegion"
        case .NineINE: return "9INE"
        case .BNE: return "Bad News Eagles"
        case .Endpoint: return "Endpoint"
        case .PARAVISION: return "PARAVISION"
        case .AVANGAR: return "AVANGAR"
        case .DRILLAS: return "DRILLAS"
        case .MADLions: return "MADLIONS"
        case .PASSIONUA: return "PASSIONUA"
        case .Gambit: return "Gambit"
        case .IntoTheBreach: return "Into the Breach"
        case .Epsilon: return "Epsilon"
        case .MovistarRiders: return "Movistar Riders"
        case .TSM: return "TSM"
        case .Titan: return "Titan"
        case .LDLC: return "LDLC"
        case .Luminosity: return "Luminosity"
        case .SK: return "SK"
        case .MIBR: return "MIBR"
        case .REDCanids: return "Red Canids"
        case .ZeroZeroNation: return "00Nation"
        case .ATK: return "ATK"
        case .Dignitas: return "Dignitas"
        case .Envy: return "Envy"
        case .MongolZ: return "MongolZ"
        case .VegaSquadron: return "Vega Squadron"
        case .Nemiga: return "nemiga"
        case .IHC: return "IHC"
        case .Checkmate: return "Checkmate"
        case .HAVU: return "HAVU"
        case .Nexus: return "Nexus"
        case .CopenhagenWolves: return "Copenhagen Wolves"
        case .other(let s): return s
        }
    }
}

// MARK: - RichPlayer

struct RichPlayer: Codable, Identifiable, Equatable {
    var id = UUID()

    // Basis
    let name: String
    let nation: Nation
    let roles: [Role]
    let teamHistory: [Team]

    // Geburtsdatum – Alter wird dynamisch berechnet
    let birthDate: Date
    let eDPI: Int

    // Stats
    let kills: Int
    let deaths: Int
    let grenade: Int
    let sniper: Int
    let rifle: Int
    let aces: Int
    let four_Ks: Int
    let zero_Ks: Int
    let mapsPlayed: Int

    // Achievements / Extras
    let grandSlams: Int
    let majors: Int
    let sTierTrophies: Int
    let hltvMVPs: Int
    let majorMVPs: Int   // <<< NEU

    // Dynamisch berechnet (immer aktuell)
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    /// KD wird aus kills/deaths berechnet.
    /// Falls deaths == 0: gib kills als KD zurück (vermeidet Division durch 0).
    var kd: Double {
        guard deaths > 0 else { return kills > 0 ? Double(kills) : 0 }
        return Double(kills) / Double(deaths)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case name, nation, roles, teamHistory
        case birthDate, eDPI
        case kills, deaths, grenade, sniper, rifle, aces, four_Ks, zero_Ks, mapsPlayed
        case grandSlams, majors, sTierTrophies, hltvMVPs, majorMVPs
    }

    static let dateFormatterYYYYMMDD: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        name         = try c.decode(String.self, forKey: .name)
        nation       = try c.decode(Nation.self, forKey: .nation)
        roles        = try c.decode([Role].self, forKey: .roles)
        teamHistory  = try c.decode([Team].self, forKey: .teamHistory)

        let birthStr = try c.decode(String.self, forKey: .birthDate)
        guard let d = RichPlayer.dateFormatterYYYYMMDD.date(from: birthStr) else {
            throw DecodingError.dataCorruptedError(forKey: .birthDate, in: c, debugDescription: "Expected yyyy-MM-dd")
        }
        birthDate = d

        eDPI        = try c.decode(Int.self, forKey: .eDPI)

        kills       = try c.decode(Int.self, forKey: .kills)
        deaths      = try c.decode(Int.self, forKey: .deaths)
        grenade     = try c.decode(Int.self, forKey: .grenade)
        sniper      = try c.decode(Int.self, forKey: .sniper)
        rifle       = try c.decode(Int.self, forKey: .rifle)
        aces        = try c.decode(Int.self, forKey: .aces)
        four_Ks     = try c.decode(Int.self, forKey: .four_Ks)
        zero_Ks     = try c.decode(Int.self, forKey: .zero_Ks)
        mapsPlayed  = try c.decode(Int.self, forKey: .mapsPlayed)

        grandSlams     = try c.decode(Int.self, forKey: .grandSlams)
        majors         = try c.decode(Int.self, forKey: .majors)
        sTierTrophies  = try c.decode(Int.self, forKey: .sTierTrophies)
        hltvMVPs       = try c.decode(Int.self, forKey: .hltvMVPs)
        majorMVPs      = try c.decode(Int.self, forKey: .majorMVPs)
    }

    // Optional convenience init (Tests)
    init(
        name: String, nation: Nation, roles: [Role], teamHistory: [Team],
        birthDate: Date, eDPI: Int,
        kills: Int, deaths: Int, grenade: Int, sniper: Int, rifle: Int,
        aces: Int, four_Ks: Int, zero_Ks: Int, mapsPlayed: Int,
        grandSlams: Int, majors: Int, sTierTrophies: Int, hltvMVPs: Int, majorMVPs: Int
    ) {
        self.name = name
        self.nation = nation
        self.roles = roles
        self.teamHistory = teamHistory
        self.birthDate = birthDate
        self.eDPI = eDPI
        self.kills = kills
        self.deaths = deaths
        self.grenade = grenade
        self.sniper = sniper
        self.rifle = rifle
        self.aces = aces
        self.four_Ks = four_Ks
        self.zero_Ks = zero_Ks
        self.mapsPlayed = mapsPlayed
        self.grandSlams = grandSlams
        self.majors = majors
        self.sTierTrophies = sTierTrophies
        self.hltvMVPs = hltvMVPs
        self.majorMVPs = majorMVPs
    }
}
