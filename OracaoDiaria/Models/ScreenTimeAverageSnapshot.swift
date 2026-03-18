//
//  ScreenTimeAverageSnapshot.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import Foundation

struct ScreenTimeAverageSnapshot: Equatable {
    let headlineDurationText: String
    let averageDurationText: String
    let impactPercentage: Int
    let annualDaysLost: Int
    let detailText: String
}

enum ScreenTimeSnapshotStore {
    private static let suiteName = "group.andresouza.OracaoDiaria.shared"
    private static let headlineKey = "screen_time_headline_duration"
    private static let averageKey = "screen_time_average_duration"
    private static let impactKey = "screen_time_impact_percentage"
    private static let annualDaysKey = "screen_time_annual_days_lost"
    private static let detailKey = "screen_time_detail_text"

    static func load() -> ScreenTimeAverageSnapshot? {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard

        guard
            let headlineDurationText = defaults.string(forKey: headlineKey),
            let averageDurationText = defaults.string(forKey: averageKey),
            let detailText = defaults.string(forKey: detailKey)
        else {
            return nil
        }

        let impactPercentage = max(1, defaults.integer(forKey: impactKey))
        let annualDaysLost = max(1, defaults.integer(forKey: annualDaysKey))

        return ScreenTimeAverageSnapshot(
            headlineDurationText: headlineDurationText,
            averageDurationText: averageDurationText,
            impactPercentage: impactPercentage,
            annualDaysLost: annualDaysLost,
            detailText: detailText
        )
    }
}
