//
//  OfficialScreenTimeReportView.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import DeviceActivity
import SwiftUI
import _DeviceActivity_SwiftUI

extension DeviceActivityReport.Context {
    static let officialDailyAverage = Self("official-daily-average")
}

extension DeviceActivityFilter {
    static var officialDailyAverage: Self {
        let calendar = Calendar.current
        let endDate = Date()
        let startOfToday = calendar.startOfDay(for: endDate)
        let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday

        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: startDate, end: endDate)),
            users: .all,
            devices: .all
        )
    }
}

struct OfficialScreenTimeReportView: View {
    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("📱 Seu tempo de tela ⏳")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Text("Um retrato real de quanto do seu dia já está indo pro celular.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            DeviceActivityReport(.officialDailyAverage, filter: .officialDailyAverage)
                .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 180, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            HStack(spacing: 10) {
                ScreenTimePill(emoji: "🗓️", text: "Últimos 14 dias")
                ScreenTimePill(emoji: "✅", text: "Dado oficial")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct ScreenTimePill: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Color.black.opacity(0.72))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.05))
        )
    }
}
