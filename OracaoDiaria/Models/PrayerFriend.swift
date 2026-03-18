//
//  PrayerFriend.swift
//  OracaoDiaria
//
//  Created by OpenCode on 18/03/26.
//

import Foundation
import SwiftUI

struct PrayerFriend: Identifiable {
    let id = UUID()
    let name: String
    let statusText: String
    let streak: Int
    let badgeColor: Color

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters)
    }

    static let samples: [PrayerFriend] = [
        PrayerFriend(
            name: "Ana Clara",
            statusText: "Já fez a oração de hoje e está firme na rotina.",
            streak: 6,
            badgeColor: Color(red: 0.26, green: 0.56, blue: 0.42)
        ),
        PrayerFriend(
            name: "Lucas",
            statusText: "Ainda não apareceu hoje. Vai dar para cutucar depois.",
            streak: 2,
            badgeColor: Color(red: 0.86, green: 0.53, blue: 0.18)
        ),
        PrayerFriend(
            name: "Marina",
            statusText: "Conseguiu manter a manhã protegida mais uma vez.",
            streak: 11,
            badgeColor: Color(red: 0.29, green: 0.57, blue: 0.92)
        ),
    ]
}
