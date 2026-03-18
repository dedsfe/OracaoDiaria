//
//  MorningPrayerMonitorExtension.swift
//  MorningPrayerMonitorExtension
//
//  Created by Codex on 17/03/26.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class MorningPrayerMonitorExtension: DeviceActivityMonitor {
    private let managedSettingsStore = ManagedSettingsStore()
    private let sharedStore = MorningPrayerBlockSharedStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard
            activity == MorningPrayerBlockConfiguration.activityName,
            let configuration = sharedStore.load(),
            configuration.isEnabled,
            configuration.hasSelection
        else {
            clearShield()
            return
        }

        applyShield(using: configuration)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }

    private func applyShield(using configuration: MorningPrayerBlockConfiguration) {
        managedSettingsStore.shield.applications = configuration.applicationTokens.isEmpty
            ? nil
            : configuration.applicationTokens

        managedSettingsStore.shield.applicationCategories = configuration.categoryTokens.isEmpty
            ? nil
            : .specific(configuration.categoryTokens)

        managedSettingsStore.shield.webDomains = configuration.webDomainTokens.isEmpty
            ? nil
            : configuration.webDomainTokens
    }

    private func clearShield() {
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.applicationCategories = nil
        managedSettingsStore.shield.webDomains = nil
    }
}

private struct MorningPrayerBlockConfiguration: Codable {
    static let activityName = DeviceActivityName("daily-morning-prayer-block")

    let wakeHour: Int
    let wakeMinute: Int
    let reminderLeadMinutes: Int
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>
    let webDomainTokens: Set<WebDomainToken>
    let isEnabled: Bool

    var hasSelection: Bool {
        !applicationTokens.isEmpty || !categoryTokens.isEmpty || !webDomainTokens.isEmpty
    }
}

private struct MorningPrayerBlockSharedStore {
    private enum Keys {
        static let configuration = "morningPrayerBlockConfiguration.v1"
    }

    private static let appGroupIdentifier = "group.andresouza.OracaoDiaria"

    private let defaults = UserDefaults(suiteName: appGroupIdentifier)
    private let decoder = PropertyListDecoder()

    func load() -> MorningPrayerBlockConfiguration? {
        guard
            let defaults,
            let data = defaults.data(forKey: Keys.configuration)
        else {
            return nil
        }

        return try? decoder.decode(MorningPrayerBlockConfiguration.self, from: data)
    }
}
