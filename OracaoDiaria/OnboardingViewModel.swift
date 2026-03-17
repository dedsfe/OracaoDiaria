//
//  OnboardingViewModel.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import Combine
import Foundation

enum OnboardingNavigationDirection {
    case forward
    case backward
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var stepIndex = 0
    @Published var navigationDirection: OnboardingNavigationDirection = .forward
    @Published var showsCommitmentCelebration = false
    @Published var data = OnboardingData()

    let totalSteps = 15
    let progressStageCount = 5
    let screenTimeAccess: ScreenTimeAccessController
    let notificationAccess: NotificationAccessController
    private var cancellables: Set<AnyCancellable> = []

    init(
        screenTimeAccess: ScreenTimeAccessController,
        notificationAccess: NotificationAccessController
    ) {
        self.screenTimeAccess = screenTimeAccess
        self.notificationAccess = notificationAccess
        bindDependencies()
    }

    var isIntroStep: Bool {
        stepIndex == 0
    }

    var isFinalStep: Bool {
        stepIndex == totalSteps - 1
    }

    var showsProgressHeader: Bool {
        (1...5).contains(stepIndex)
    }

    var showsGlobalNavigation: Bool {
        stepIndex > 0 && stepIndex != 6 && stepIndex != 7
    }

    var progressStepNumber: Int {
        min(max(stepIndex, 1), progressStageCount)
    }

    var progressValue: Double {
        Double(progressStepNumber) / Double(progressStageCount)
    }

    var canProceed: Bool {
        switch stepIndex {
        case 3:
            return !data.trimmedName.isEmpty
        case 5:
            return screenTimeAccess.isAuthorized
        case 8:
            return !data.selectedGoals.isEmpty
        case 9:
            return !data.trimmedVision.isEmpty
        case 12:
            return data.hasBlockingSelection
        default:
            return true
        }
    }

    func onAppear() {
        screenTimeAccess.refresh()
        notificationAccess.refresh()
    }

    func goBack() {
        guard stepIndex > 0 else { return }
        navigationDirection = .backward
        stepIndex -= 1
    }

    func goForward() {
        if stepIndex == 5 {
            screenTimeAccess.refreshSnapshot()
            navigationDirection = .forward
            stepIndex = 6
            return
        }

        guard stepIndex < totalSteps - 1 else { return }
        navigationDirection = .forward
        stepIndex += 1
    }

    func handlePrimaryAction() {
        if isFinalStep {
            showsCommitmentCelebration = true
        } else {
            goForward()
        }
    }

    func completeOnboarding() async -> String {
        if data.notificationsEnabled {
            if !notificationAccess.isAuthorized {
                await notificationAccess.requestAuthorization()
            }

            if notificationAccess.isAuthorized {
                await notificationAccess.scheduleMorningReminder(
                    wakeUpTime: data.wakeUpTime,
                    leadMinutes: data.reminderLeadMinutes
                )
            }
        } else {
            await notificationAccess.clearMorningReminder()
        }

        PrayerProgressStore.savePreferredDurationMinutes(data.prayerDurationMinutes)

        return data.trimmedName
    }

    private func bindDependencies() {
        screenTimeAccess.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        notificationAccess.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
