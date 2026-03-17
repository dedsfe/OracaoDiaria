//
//  PrayerIdleHomeView.swift
//  OracaoDiaria
//
//  Created by Codex on 16/03/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PrayerIdleHomeView: View {
    var body: some View {
        PrayerWallpaperImage(name: "backgroundhome")
            .background(Color.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

struct PrayerStartAccessoryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.80)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.extraLarge)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

private struct PrayerWallpaperImage: View {
    let name: String

    var body: some View {
        Group {
            if let image = PrayerWallpaperCache.image(named: name) {
                Image(uiImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}

#if canImport(UIKit)
private enum PrayerWallpaperCache {
    private static var cache: [String: UIImage] = [:]

    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] {
            return cached
        }

        guard
            let path = Bundle.main.path(forResource: name, ofType: "png"),
            let image = UIImage(contentsOfFile: path)
        else {
            return nil
        }

        cache[name] = image
        return image
    }
}
#else
private enum PrayerWallpaperCache {
    static func image(named _: String) -> Never? { nil }
}
#endif

struct PrayerIdleHomeView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerIdleHomeView()
        .previewDevice("iPhone 16 Pro")
    }
}
