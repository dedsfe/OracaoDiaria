//
//  OfficialDailyAverageReport.swift
//  ScreenTimeReportExtension
//
//  Created by Codex on 15/03/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    static let officialDailyAverage = Self("official-daily-average")
}

struct OfficialDailyAverageConfiguration: Hashable, Sendable {
    let headlineDurationText: String
    let averageDurationText: String
    let impactPercentage: Int
    let annualDaysLost: Int
    let detailText: String
}

struct OfficialDailyAverageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .officialDailyAverage
    let content: (OfficialDailyAverageConfiguration) -> OfficialDailyAverageView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> OfficialDailyAverageConfiguration {
        let summary = await data
            .flatMap { $0.activitySegments }
            .reduce(into: ActivitySummary()) { partial, segment in
                guard segment.totalActivityDuration > 0 else { return }
                partial.totalDuration += segment.totalActivityDuration
                partial.activeDayCount += 1
            }

        guard summary.activeDayCount > 0 else {
            let configuration = OfficialDailyAverageConfiguration(
                headlineDurationText: "algum tempo",
                averageDurationText: "Sem dados ainda",
                impactPercentage: 1,
                annualDaysLost: 1,
                detailText: "O iPhone ainda não liberou uso suficiente para calcular sua média diária."
            )
            ScreenTimeSnapshotPersistence.save(configuration)
            return configuration
        }

        let averageDuration = summary.totalDuration / Double(summary.activeDayCount)
        let headlineFormatter = DateComponentsFormatter()
        headlineFormatter.allowedUnits = [.hour, .minute]
        headlineFormatter.unitsStyle = .full
        headlineFormatter.zeroFormattingBehavior = .dropAll

        let averageFormatter = DateComponentsFormatter()
        averageFormatter.allowedUnits = [.hour, .minute]
        averageFormatter.unitsStyle = .full
        averageFormatter.zeroFormattingBehavior = .dropAll

        let formattedHeadlineAverage = headlineFormatter.string(from: averageDuration) ?? "algum tempo"
        let formattedAverage = averageFormatter.string(from: averageDuration) ?? "0 min"
        let impactPercentage = min(100, max(1, Int((300 / max(averageDuration, 60)).rounded())))
        let annualDaysLost = max(1, Int(((averageDuration * 365) / 86_400).rounded()))
        let detailText: String
        if summary.activeDayCount == 1 {
            detailText = "Média diária oficial com base no último dia disponível."
        } else {
            detailText = "Média diária oficial com base nos últimos \(summary.activeDayCount) dias com uso."
        }

        let configuration = OfficialDailyAverageConfiguration(
            headlineDurationText: formattedHeadlineAverage,
            averageDurationText: formattedAverage,
            impactPercentage: impactPercentage,
            annualDaysLost: annualDaysLost,
            detailText: detailText
        )
        ScreenTimeSnapshotPersistence.save(configuration)
        return configuration
    }
}

private struct ActivitySummary {
    var totalDuration: TimeInterval = 0
    var activeDayCount = 0
}

private enum ScreenTimeSnapshotPersistence {
    private static let suiteName = "group.andresouza.OracaoDiaria.shared"
    private static let headlineKey = "screen_time_headline_duration"
    private static let averageKey = "screen_time_average_duration"
    private static let impactKey = "screen_time_impact_percentage"
    private static let annualDaysKey = "screen_time_annual_days_lost"
    private static let detailKey = "screen_time_detail_text"

    static func save(_ configuration: OfficialDailyAverageConfiguration) {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.set(configuration.headlineDurationText, forKey: headlineKey)
        defaults.set(configuration.averageDurationText, forKey: averageKey)
        defaults.set(configuration.impactPercentage, forKey: impactKey)
        defaults.set(configuration.annualDaysLost, forKey: annualDaysKey)
        defaults.set(configuration.detailText, forKey: detailKey)
    }
}
