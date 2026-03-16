//
//  ScreenTimeReportExtension.swift
//  ScreenTimeReportExtension
//
//  Created by Codex on 15/03/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        OfficialDailyAverageReport { configuration in
            OfficialDailyAverageView(configuration: configuration)
        }
    }
}
