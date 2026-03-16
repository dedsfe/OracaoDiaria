//
//  OnboardingStyle.swift
//  OracaoDiaria
//
//  Created by Codex on 14/03/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum OnboardingHaptic {
    case selection
    case light
    case medium
    case heavy
    case success
}

func triggerOnboardingHaptic(_ haptic: OnboardingHaptic) {
#if canImport(UIKit)
    switch haptic {
    case .selection:
        OnboardingHapticCache.selection.selectionChanged()
    case .light:
        OnboardingHapticCache.light.impactOccurred()
    case .medium:
        OnboardingHapticCache.medium.impactOccurred()
    case .heavy:
        OnboardingHapticCache.heavy.impactOccurred()
    case .success:
        OnboardingHapticCache.notification.notificationOccurred(.success)
    }
#endif
}

struct OnboardingBackground: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            OnboardingAssetCache.backgroundImage
                .resizable()
                .scaledToFill()
                .scaleEffect(isAnimating ? 1.008 : 1.0)
                .offset(y: isAnimating ? -4 : 0)
                .clipped()
                .animation(.easeInOut(duration: 18).repeatForever(autoreverses: true), value: isAnimating)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.clear,
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            isAnimating = true
        }
    }
}

enum CardPose {
    case hero
    case tiltLeft
    case tiltRight
    case quietLeft
    case quietRight
    case centered

    var alignment: Alignment {
        switch self {
        case .tiltLeft, .quietLeft:
            return .leading
        case .tiltRight, .quietRight:
            return .trailing
        case .hero, .centered:
            return .center
        }
    }

    var xOffset: CGFloat {
        switch self {
        case .hero, .centered:
            return 0
        case .tiltLeft:
            return -8
        case .tiltRight:
            return 8
        case .quietLeft:
            return -4
        case .quietRight:
            return 4
        }
    }

    var floatDistance: CGFloat {
        switch self {
        case .hero:
            return 5
        case .tiltLeft, .tiltRight:
            return 4
        case .quietLeft, .quietRight, .centered:
            return 3
        }
    }

    var duration: Double {
        switch self {
        case .hero:
            return 4.0
        case .tiltLeft, .tiltRight:
            return 4.6
        case .quietLeft, .quietRight, .centered:
            return 3.8
        }
    }
}

struct StitchedCard<Content: View>: View {
    private let pose: CardPose
    @ViewBuilder private let content: Content

    init(
        pose: CardPose = .centered,
        @ViewBuilder content: () -> Content
    ) {
        self.pose = pose
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }
}

struct PrimaryOnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 23, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryOnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

#if canImport(UIKit)
private enum OnboardingHapticCache {
    static let selection = UISelectionFeedbackGenerator()
    static let light = UIImpactFeedbackGenerator(style: .light)
    static let medium = UIImpactFeedbackGenerator(style: .medium)
    static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    static let notification = UINotificationFeedbackGenerator()
}

private enum OnboardingAssetCache {
    static let backgroundImage: Image = {
        if
            let path = Bundle.main.path(forResource: "backgroundimg", ofType: "png"),
            let image = UIImage(contentsOfFile: path)
        {
            return Image(uiImage: image)
        }

        return Image("backgroundimg")
    }()
}
#endif
