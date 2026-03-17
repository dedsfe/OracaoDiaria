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
        GeometryReader { proxy in
            PrayerWallpaperImage(name: "backgroundhome")
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color.black)
                .ignoresSafeArea()
        }
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
                .padding(.vertical, 18)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .frame(maxWidth: 430)
        .padding(.horizontal, 48)
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
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
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(1.015)
            } else {
                Color.black
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
