//
//  NotificationAccessController.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationAccessController: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isRequestingAuthorization = false
    @Published var lastErrorMessage: String?

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-prayer-reminder"

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func refresh() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async {
        guard !isRequestingAuthorization else { return }

        isRequestingAuthorization = true
        lastErrorMessage = nil

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus

            if !granted {
                lastErrorMessage = "As notificações foram recusadas no iPhone."
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }

        isRequestingAuthorization = false
    }

    func scheduleMorningReminder(wakeUpTime: Date, leadMinutes: Int) async {
        await clearMorningReminder()
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let reminderDate = calendar.date(byAdding: .minute, value: -leadMinutes, to: wakeUpTime) ?? wakeUpTime
        let components = calendar.dateComponents([.hour, .minute], from: reminderDate)

        let content = UNMutableNotificationContent()
        content.title = "Hora de orar"
        content.body = "Antes de tocar no celular, fale com Deus primeiro."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )

        do {
            try await center.add(request)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearMorningReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [reminderIdentifier])
    }
}
