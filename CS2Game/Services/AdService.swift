//
//  AdService.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import Foundation
import SwiftUI

protocol AdServicing {
    func preloadInterstitial(placement: String)
    func showInterstitial(placement: String, from root: UIViewController?) -> Bool
    func bannerView() -> AnyView? // später echte Banner-View einhängen
}

final class AdService: AdServicing {
    static let shared: AdServicing = AdService()
    private init() {}
    func preloadInterstitial(placement: String) {}
    func showInterstitial(placement: String, from root: UIViewController?) -> Bool { return false }
    func bannerView() -> AnyView? { return nil }
}
