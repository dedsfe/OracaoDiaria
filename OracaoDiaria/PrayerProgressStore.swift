//
//  PrayerProgressStore.swift
//  OracaoDiaria
//
//  Created by Codex on 16/03/26.
//

import Combine
import Foundation

@MainActor
final class PrayerProgressStore: ObservableObject {
    private enum DurationBounds {
        static let minimum = 1
        static let maximum = 60
        static let `default` = 60
    }

    private struct PersistedState: Codable {
        var preferredDurationMinutes: Int
        var completedDayKeys: [String]
        var currentRemainingSeconds: Int
        var activeEndDate: Date?
        var awaitingConfirmationDayKey: String?
        var hasPrayerSessionInProgress: Bool?
    }

    private enum Keys {
        static let state = "prayerProgressState.v1"
    }

    @Published private(set) var preferredDurationMinutes: Int
    @Published private(set) var completedDayKeys: Set<String>
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var activeEndDate: Date?
    @Published private(set) var awaitingConfirmationDayKey: String?
    @Published private(set) var hasPrayerSessionInProgress: Bool
    @Published var showsCompletionPopup = false

    private let defaults: UserDefaults
    private var tickerTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let state = Self.loadState(from: defaults)
        preferredDurationMinutes = Self.clampedDurationMinutes(state.preferredDurationMinutes)
        completedDayKeys = Set(state.completedDayKeys)
        remainingSeconds = max(state.currentRemainingSeconds, 0)
        activeEndDate = state.activeEndDate
        awaitingConfirmationDayKey = state.awaitingConfirmationDayKey
        hasPrayerSessionInProgress = state.hasPrayerSessionInProgress ?? (
            state.activeEndDate != nil
                || state.awaitingConfirmationDayKey != nil
                || state.currentRemainingSeconds < (Self.clampedDurationMinutes(state.preferredDurationMinutes) * 60)
        )

        if remainingSeconds == 0, activeEndDate == nil, awaitingConfirmationDayKey == nil {
            remainingSeconds = preferredDurationMinutes * 60
        }

        refreshFromClock()
        startTickerIfNeeded()
    }

    deinit {
        tickerTask?.cancel()
    }

    var isRunning: Bool {
        activeEndDate != nil
    }

    var isAwaitingConfirmation: Bool {
        awaitingConfirmationDayKey != nil
    }

    var canAdjustDuration: Bool {
        !isRunning && !isAwaitingConfirmation && remainingSeconds == defaultDurationSeconds
    }

    var prayedToday: Bool {
        hasCompletedPrayer(on: Date())
    }

    var streakCount: Int {
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: Date())

        if !hasCompletedPrayer(on: current) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else {
                return 0
            }
            current = previous
        }

        var count = 0
        while hasCompletedPrayer(on: current) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else {
                break
            }
            current = previous
        }

        return count
    }

    var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "LLLL"
        let month = formatter.string(from: Date()).capitalized
        return "\(month) \(Calendar.current.component(.year, from: Date()))"
    }

    var monthlyPrayerCount: Int {
        completedDates(inSameMonthAs: Date()).count
    }

    var monthCells: [Date?] {
        let calendar = Calendar.current
        let today = Date()
        let monthInterval = calendar.dateInterval(of: .month, for: today)
        let startOfMonth = monthInterval?.start ?? today
        let dayRange = calendar.range(of: .day, in: .month, for: today) ?? 1..<31
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingSlots = (firstWeekday + 5) % 7
        let dates = dayRange.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: startOfMonth)
        }

        return Array(repeating: nil, count: leadingSlots) + dates
    }

    var defaultDurationSeconds: Int {
        preferredDurationMinutes * 60
    }

    var countdownProgress: Double {
        guard defaultDurationSeconds > 0 else { return 0 }
        let clampedRemaining = min(max(remainingSeconds, 0), defaultDurationSeconds)
        let progress = 1 - (Double(clampedRemaining) / Double(defaultDurationSeconds))
        return min(max(progress, 0), 1)
    }

    static func savePreferredDurationMinutes(_ minutes: Int, defaults: UserDefaults = .standard) {
        var state = loadState(from: defaults)
        state.preferredDurationMinutes = clampedDurationMinutes(minutes)

        if state.activeEndDate == nil && state.awaitingConfirmationDayKey == nil {
            state.currentRemainingSeconds = state.preferredDurationMinutes * 60
        }

        saveState(state, to: defaults)
    }

    func refreshFromClock() {
        guard let activeEndDate else {
            if remainingSeconds == 0, awaitingConfirmationDayKey == nil {
                remainingSeconds = defaultDurationSeconds
                persist()
            }
            return
        }

        let remaining = Int(ceil(activeEndDate.timeIntervalSinceNow))
        if remaining <= 0 {
            finishPrayerCountdown()
            return
        }

        remainingSeconds = remaining
    }

    func handlePrimaryAction() {
        if isRunning {
            pausePrayer()
        } else {
            startOrResumePrayer()
        }
    }

    func handleTimerInteraction() {
        if isAwaitingConfirmation {
            confirmPrayerCompletion()
        } else {
            handlePrimaryAction()
        }
    }

    func resetPrayer() {
        tickerTask?.cancel()
        activeEndDate = nil
        awaitingConfirmationDayKey = nil
        hasPrayerSessionInProgress = false
        remainingSeconds = defaultDurationSeconds
        MorningPrayerBlockController.shared.syncShieldState(
            prayedToday: prayedToday,
            isPrayerSessionInProgress: hasPrayerSessionInProgress
        )
        persist()
    }

    func confirmPrayerCompletion() {
        let dayKey = awaitingConfirmationDayKey ?? Self.dayKey(for: Date())
        // TODO: Persist how many prayer minutes the user completed on each day,
        // so the streak/history experience can show daily totals.
        completedDayKeys.insert(dayKey)
        awaitingConfirmationDayKey = nil
        hasPrayerSessionInProgress = false
        remainingSeconds = defaultDurationSeconds
        MorningPrayerBlockController.shared.unlockAfterPrayerCompletion()
        showsCompletionPopup = true
        persist()
        triggerOnboardingHaptic(.success)
    }

    func dismissCompletionPopup() {
        showsCompletionPopup = false
    }

    func triggerCompletionPopupDebug() {
        showsCompletionPopup = false

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(60))
            self?.showsCompletionPopup = true
        }
    }

    func hasCompletedPrayer(on date: Date) -> Bool {
        completedDayKeys.contains(Self.dayKey(for: date))
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func updatePreferredDurationIfNeeded(_ minutes: Int) {
        let normalizedMinutes = Self.clampedDurationMinutes(minutes)
        guard normalizedMinutes != preferredDurationMinutes else { return }

        preferredDurationMinutes = normalizedMinutes
        if !isRunning && !isAwaitingConfirmation {
            remainingSeconds = defaultDurationSeconds
        }
        persist()
    }

    private func startOrResumePrayer() {
        guard !isAwaitingConfirmation else { return }

        if remainingSeconds <= 0 {
            remainingSeconds = defaultDurationSeconds
        }

        hasPrayerSessionInProgress = true
        activeEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        MorningPrayerBlockController.shared.syncShieldState(
            prayedToday: prayedToday,
            isPrayerSessionInProgress: hasPrayerSessionInProgress
        )
        persist()
        startTickerIfNeeded()
        triggerOnboardingHaptic(.medium)
    }

    private func pausePrayer() {
        guard let activeEndDate else { return }

        tickerTask?.cancel()
        remainingSeconds = max(Int(ceil(activeEndDate.timeIntervalSinceNow)), 1)
        self.activeEndDate = nil
        persist()
        triggerOnboardingHaptic(.light)
    }

    private func finishPrayerCountdown() {
        tickerTask?.cancel()
        let completedDayKey = activeEndDate.map(Self.dayKey(for:)) ?? Self.dayKey(for: Date())
        activeEndDate = nil
        remainingSeconds = 0
        awaitingConfirmationDayKey = completedDayKey
        persist()
        triggerOnboardingHaptic(.success)
    }

    private func startTickerIfNeeded() {
        tickerTask?.cancel()

        guard activeEndDate != nil else { return }

        tickerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                self.refreshFromClock()

                if !self.isRunning {
                    break
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func completedDates(inSameMonthAs referenceDate: Date) -> [Date] {
        completedDayKeys.compactMap(Self.date(for:)).filter {
            Calendar.current.isDate($0, equalTo: referenceDate, toGranularity: .month)
        }
    }

    private func persist() {
        let state = PersistedState(
            preferredDurationMinutes: preferredDurationMinutes,
            completedDayKeys: Array(completedDayKeys).sorted(),
            currentRemainingSeconds: remainingSeconds,
            activeEndDate: activeEndDate,
            awaitingConfirmationDayKey: awaitingConfirmationDayKey,
            hasPrayerSessionInProgress: hasPrayerSessionInProgress
        )

        Self.saveState(state, to: defaults)
    }

    private static func loadState(from defaults: UserDefaults) -> PersistedState {
        guard
            let data = defaults.data(forKey: Keys.state),
            let decoded = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            return PersistedState(
                preferredDurationMinutes: DurationBounds.default,
                completedDayKeys: [],
                currentRemainingSeconds: DurationBounds.default * 60,
                activeEndDate: nil,
                awaitingConfirmationDayKey: nil,
                hasPrayerSessionInProgress: false
            )
        }

        return decoded
    }

    private static func saveState(_ state: PersistedState, to defaults: UserDefaults) {
        guard let encoded = try? JSONEncoder().encode(state) else { return }
        defaults.set(encoded, forKey: Keys.state)
    }

    private static func clampedDurationMinutes(_ minutes: Int) -> Int {
        min(max(minutes, DurationBounds.minimum), DurationBounds.maximum)
    }

    private static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private static func date(for dayKey: String) -> Date? {
        dayFormatter.date(from: dayKey)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
