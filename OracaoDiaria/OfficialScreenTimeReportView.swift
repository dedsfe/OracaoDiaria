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
        DeviceActivityReport(.officialDailyAverage, filter: .officialDailyAverage)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
    }
}
