//
//  OfficialDailyAverageView.swift
//  ScreenTimeReportExtension
//
//  Created by Codex on 15/03/26.
//

import SwiftUI

struct OfficialDailyAverageView: View {
    let configuration: OfficialDailyAverageConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seu tempo médio por dia")
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)

            Text(configuration.averageDurationText)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)

            Text(configuration.detailText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.black.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}
