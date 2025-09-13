//
//  SettingsView.swift
//  CS2Game
//
//  Created by Maximilian Kunzmann on 10.09.25.
//

import SwiftUI

struct SettingsView: View {
    // Persistente Toggle-States (später für echte Analytics/Crashes nutzbar)
    @AppStorage("settings_analytics_enabled") private var analyticsEnabled: Bool = false
    @AppStorage("settings_crash_enabled")     private var crashEnabled: Bool = false

    // Bestätigungsdialoge
    @State private var showClearAllConfirm = false
    @State private var showClearBingoConfirm = false
    @State private var showClearBaseConfirm = false

    private let privacyURL  = URL(string: "https://Maxikiiing.github.io/CSData/privacy.html")!
    private let supportURL  = URL(string: "https://Maxikiiing.github.io/CSData/support.html")!


    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {

                    // TITLE
                    Text("Settings")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Theme.ctBlue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // PREFERENCES
                    SectionHeader("Preferences")
                    VStack(spacing: 10) {
                        ToggleRow(
                            title: "Anonymous Analytics",
                            subtitle: "Help improve the app by sharing usage stats.",
                            isOn: $analyticsEnabled
                        )
                        .onChange(of: analyticsEnabled) { _, newVal in
                            AnalyticsService.shared.setEnabled(newVal)
                            AnalyticsService.shared.event("settings_analytics", params: ["enabled": newVal])
                        }
                        ToggleRow(
                            title: "Crash Reports",
                            subtitle: "Send crash data to diagnose issues.",
                            isOn: $crashEnabled
                        )
                        .onChange(of: crashEnabled) { _, newVal in
                            CrashService.shared.setEnabled(newVal)
                            AnalyticsService.shared.event("settings_crash", params: ["enabled": newVal])
                        }
                    }

                    // DATA MANAGEMENT
                    SectionHeader("Manage Data")
                    VStack(spacing: 10) {
                        ActionRow(
                            title: "Clear Bingo Leaderboards",
                            systemImage: "trash",
                            action: { showClearBingoConfirm = true }
                        )
                        ActionRow(
                            title: "Clear Base Leaderboards",
                            systemImage: "trash",
                            action: { showClearBaseConfirm = true }
                        )
                        ActionRow(
                            title: "Clear All Leaderboards",
                            systemImage: "trash.fill",
                            action: { showClearAllConfirm = true }
                        )
                    }

                    // LINKS
                    SectionHeader("Links")
                    VStack(spacing: 10) {
                        LinkRow(title: "Privacy Policy", url: privacyURL)
                        LinkRow(title: "Support", url: supportURL)
                    }

                    // ABOUT
                    SectionHeader("About")
                    AboutRow(
                        appName: Bundle.main.displayName,
                        version: Bundle.main.appVersionString,
                        build: Bundle.main.appBuildString
                    )
                    SectionHeader("Legal")
                    LegalCard()


                    Spacer(minLength: 8)
                }
                .frame(maxWidth: 360)
                .padding()
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            AnalyticsService.shared.screen("Settings")
        }
        // MARK: - Alerts
        .alert("Clear Bingo Leaderboards?", isPresented: $showClearBingoConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                BingoLeaderboard.shared.clearAll()
            }
        } message: {
            Text("This removes all local Bingo leaderboard entries.")
        }
        .alert("Clear Base Leaderboards?", isPresented: $showClearBaseConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                BaseLeaderboard.shared.clearAll()
            }
        } message: {
            Text("This removes all local Base leaderboard entries.")
        }
        .alert("Clear ALL Leaderboards?", isPresented: $showClearAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                BingoLeaderboard.shared.clearAll()
                BaseLeaderboard.shared.clearAll()
            }
        } message: {
            Text("This removes all local leaderboard entries (Bingo + Base).")
        }
    }
}

// MARK: - Building Blocks

private struct SectionHeader: View {
    let title: String
    init(_ t: String) { self.title = t }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.ctBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.ctBlue)
                Text(subtitle).font(.caption).foregroundStyle(Theme.ctBlueDim)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1) // CT-Theme: blauer Rand
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ActionRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(Theme.ctBlue)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBG)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.ctBlue, lineWidth: 1) // CT-Theme: blauer Rand
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private struct LinkRow: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.right.square")
                    .font(.headline)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(Theme.ctBlue)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBG)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.ctBlue, lineWidth: 1) // CT-Theme: blauer Rand
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private struct AboutRow: View {
    let appName: String
    let version: String
    let build: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appName)
                .font(.headline)
                .foregroundStyle(Theme.ctBlue)
            Text("Version \(version) (\(build))")
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Bundle helpers

private extension Bundle {
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    }
    var appVersionString: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    var appBuildString: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
private struct LegalCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Disclaimer")
                .font(.headline)
                .foregroundStyle(Theme.ctBlue)

            Text("This app is not affiliated with or endorsed by Valve or the Counter-Strike franchise. All trademarks and player/team names are the property of their respective owners. Data is aggregated from publicly available sources.")
                .font(.caption)
                .foregroundStyle(Theme.ctBlueDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Theme.cardBG)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.ctBlue, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

