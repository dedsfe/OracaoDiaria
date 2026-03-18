//
//  OnboardingModels.swift
//  OracaoDiaria
//
//  Created by Codex on 14/03/26.
//

import FamilyControls
import Foundation

enum OnboardingGoal: CaseIterable, Hashable, Identifiable {
    case prayerHabit
    case lessDistraction
    case startWithGod
    case innerPeace
    case strongerFaith

    var id: String { title }

    var title: String {
        switch self {
        case .prayerHabit:
            return "Criar hábito de oração"
        case .lessDistraction:
            return "Reduzir distrações"
        case .startWithGod:
            return "Começar o dia com Deus"
        case .innerPeace:
            return "Sentir mais paz"
        case .strongerFaith:
            return "Fortalecer minha fé"
        }
    }

    var emoji: String {
        switch self {
        case .prayerHabit:
            return "🙏"
        case .lessDistraction:
            return "📵"
        case .startWithGod:
            return "☀️"
        case .innerPeace:
            return "🕊️"
        case .strongerFaith:
            return "✝️"
        }
    }
}

struct OnboardingData {
    var name: String = ""
    var ageSelection: Int = 0
    var selectedGoals: Set<OnboardingGoal> = []
    var vision: String = ""

    var wakeUpTime: Date = Calendar.current.date(
        bySettingHour: 6,
        minute: 30,
        second: 0,
        of: Date()
    ) ?? Date()

    var prayerDurationMinutes: Int = 10
    var appSelection = FamilyActivitySelection()
    var notificationsEnabled = false
    var reminderLeadMinutes = 10

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        trimmedName.isEmpty ? "amiga" : trimmedName
    }

    var trimmedVision: String {
        vision.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var age: Int? {
        ageSelection == 0 ? nil : ageSelection
    }

    var hasBlockingSelection: Bool {
        !appSelection.applicationTokens.isEmpty ||
        !appSelection.categoryTokens.isEmpty ||
        !appSelection.webDomainTokens.isEmpty
    }

    var blockedAppsSummary: String {
        let appCount = appSelection.applicationTokens.count
        let categoryCount = appSelection.categoryTokens.count
        let domainCount = appSelection.webDomainTokens.count

        var parts: [String] = []
        if appCount > 0 {
            parts.append(appCount == 1 ? "1 aplicativo" : "\(appCount) aplicativos")
        }
        if categoryCount > 0 {
            parts.append(categoryCount == 1 ? "1 categoria" : "\(categoryCount) categorias")
        }
        if domainCount > 0 {
            parts.append(domainCount == 1 ? "1 site" : "\(domainCount) sites")
        }

        return parts.isEmpty ? "Nada selecionado" : parts.joined(separator: ", ")
    }

    var reminderSummary: String {
        notificationsEnabled ? "\(reminderLeadMinutes) min antes" : "Desligado"
    }
}
