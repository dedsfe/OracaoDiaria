//
//  MorningPrayerBlockController.swift
//  OracaoDiaria
//
//  Created by Codex on 17/03/26.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

@MainActor
final class MorningPrayerBlockController {
    static let shared = MorningPrayerBlockController()

    private let center = DeviceActivityCenter()
    private let managedSettingsStore = ManagedSettingsStore()
    private let sharedStore = MorningPrayerBlockSharedStore()

    private init() {}

    func configureBlocking(
        selection: FamilyActivitySelection,
        wakeUpTime: Date,
        reminderLeadMinutes: Int
    ) {
        let configuration = MorningPrayerBlockConfiguration(
            selection: selection,
            wakeUpTime: wakeUpTime,
            reminderLeadMinutes: reminderLeadMinutes,
            isEnabled: true
        )

        guard configuration.hasSelection else {
            disableBlocking()
            return
        }

        sharedStore.save(configuration)
        startDailyMonitoring()
        applyShield(using: configuration)
    }

    func syncShieldState(
        prayedToday: Bool,
        isPrayerSessionInProgress: Bool
    ) {
        guard
            let configuration = sharedStore.load(),
            configuration.isEnabled,
            configuration.hasSelection
        else {
            clearShield()
            return
        }

        if isPrayerSessionInProgress {
            applyShield(using: configuration)
        } else if prayedToday {
            clearShield()
        } else {
            applyShield(using: configuration)
        }
    }

    func unlockAfterPrayerCompletion() {
        clearShield()
    }

    func disableBlocking() {
        sharedStore.clear()
        center.stopMonitoring()
        clearShield()
    }

    private func startDailyMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        center.stopMonitoring()

        do {
            try center.startMonitoring(MorningPrayerBlockConfiguration.activityName, during: schedule)
        } catch {
            debugPrint("Morning prayer monitoring start failed:", error.localizedDescription)
        }
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

    init(
        selection: FamilyActivitySelection,
        wakeUpTime: Date,
        reminderLeadMinutes: Int,
        isEnabled: Bool
    ) {
        let wakeComponents = Calendar.current.dateComponents([.hour, .minute], from: wakeUpTime)
        self.wakeHour = wakeComponents.hour ?? 6
        self.wakeMinute = wakeComponents.minute ?? 30
        self.reminderLeadMinutes = reminderLeadMinutes
        self.applicationTokens = selection.applicationTokens
        self.categoryTokens = selection.categoryTokens
        self.webDomainTokens = selection.webDomainTokens
        self.isEnabled = isEnabled
    }

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
    private let encoder = PropertyListEncoder()
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

    func save(_ configuration: MorningPrayerBlockConfiguration) {
        guard
            let defaults,
            let data = try? encoder.encode(configuration)
        else {
            return
        }

        defaults.set(data, forKey: Keys.configuration)
    }

    func clear() {
        defaults?.removeObject(forKey: Keys.configuration)
    }
}
