//
//  ContentView.swift
//  OracaoDiaria
//
//  Created by André Felipe Farias Gonçalves de Souza on 13/03/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false
    @AppStorage("savedUserName") private var savedUserName = ""

    var body: some View {
        Group {
            if didCompleteOnboarding {
                MainTabRoot()
            } else {
                OnboardingFlowView(
                    didCompleteOnboarding: $didCompleteOnboarding,
                    savedName: $savedUserName
                )
            }
        }
    }
}

private enum MainAppTab: Hashable {
    case streak
    case orar
    case friends
}

private struct MainTabRoot: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var prayerProgress = PrayerProgressStore()
    @State private var selectedTab: MainAppTab = .orar

    private let friends = PrayerFriend.samples

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                StreakTabView(store: prayerProgress)
                    .tabItem {
                        Label("Streak", systemImage: "flame.fill")
                    }
                    .tag(MainAppTab.streak)

                PrayerTimerHomeView(store: prayerProgress)
                    .tabItem {
                        Label("Orar", systemImage: "timer")
                    }
                    .tag(MainAppTab.orar)

                FriendsTabView(friends: friends)
                    .tabItem {
                        Label("Amigos", systemImage: "person.2.fill")
                    }
                    .tag(MainAppTab.friends)
            }
            .toolbarBackground(.visible, for: .tabBar)

            if prayerProgress.showsCompletionPopup {
                PrayerCompletionPopup(
                    particleCount: 18,
                    layers: [.midFront, .nearFront]
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        prayerProgress.dismissCompletionPopup()
                    }
                }
                .zIndex(10)
            }
        }
        .onAppear {
            MorningPrayerBlockController.shared.syncShieldState(
                prayedToday: prayerProgress.prayedToday,
                isPrayerSessionInProgress: prayerProgress.hasPrayerSessionInProgress
            )
        }
        .onChange(of: selectedTab) {
            triggerOnboardingHaptic(.selection)
        }
        .onChange(of: prayerProgress.prayedToday) {
            MorningPrayerBlockController.shared.syncShieldState(
                prayedToday: prayerProgress.prayedToday,
                isPrayerSessionInProgress: prayerProgress.hasPrayerSessionInProgress
            )
        }
        .onChange(of: prayerProgress.hasPrayerSessionInProgress) {
            MorningPrayerBlockController.shared.syncShieldState(
                prayedToday: prayerProgress.prayedToday,
                isPrayerSessionInProgress: prayerProgress.hasPrayerSessionInProgress
            )
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            prayerProgress.refreshFromClock()
            MorningPrayerBlockController.shared.syncShieldState(
                prayedToday: prayerProgress.prayedToday,
                isPrayerSessionInProgress: prayerProgress.hasPrayerSessionInProgress
            )
        }
        .animation(.easeInOut(duration: 0.28), value: prayerProgress.showsCompletionPopup)
    }
}

private struct PrayerTimerHomeView: View {
    @ObservedObject var store: PrayerProgressStore

    var body: some View {
        PrayerIdleHomeView(store: store, showsAmbientBackground: false) { progress in
            ZStack(alignment: .topTrailing) {
                Color.black
                    .ignoresSafeArea()

                if store.showsCompletionPopup {
                    PrayerCompletionPopup(
                        particleCount: 14,
                        layers: [.far, .midBack, .nearBack]
                    ) {}
                }

                PrayerDurationTimerView(
                    store: store,
                    visualProgress: progress
                )

                #if DEBUG
                Button {
                    store.triggerCompletionPopupDebug()
                } label: {
                    Text("FX")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white, in: Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 64)
                .padding(.trailing, 20)
                #endif
            }
        }
    }
}

private struct StreakTabView: View {
    @ObservedObject var store: PrayerProgressStore
    @State private var selectedCard: StreakDashboardCard = .top

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: cardSpacing) {
                    Color.clear
                        .frame(height: visibleHeight(for: .top, in: proxy))
                        .overlay(alignment: .top) {
                            streakCardView(for: .top)
                                .frame(height: visibleHeight(for: .top, in: proxy) + topBleed(in: proxy))
                                .offset(y: -topBleed(in: proxy))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectCard(.top)
                        }

                    ForEach([StreakDashboardCard.middle, .bottom]) { card in
                        streakCardView(for: card)
                            .frame(height: visibleHeight(for: card, in: proxy))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectCard(card)
                            }
                    }
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func streakCardView(for card: StreakDashboardCard) -> some View {
        switch card {
        case .top:
            TopOpenStreakCardShape(bottomCornerRadius: 34)
                .fill(Color.white)
        case .middle:
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 0.80, green: 1.0, blue: 0.08))
        case .bottom:
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 0.06, green: 0.35, blue: 0.96))
        }
    }

    private func proportion(for card: StreakDashboardCard) -> CGFloat {
        selectedCard == card ? 0.5 : 0.25
    }

    private var cardSpacing: CGFloat {
        4
    }

    private func visibleHeight(for card: StreakDashboardCard, in proxy: GeometryProxy) -> CGFloat {
        let bottomReservedSpace = max(proxy.safeAreaInsets.bottom - 8, 12)
        let availableVisibleHeight = max(
            proxy.size.height - bottomReservedSpace - (cardSpacing * 2),
            1
        )
        return availableVisibleHeight * proportion(for: card)
    }

    private func topBleed(in proxy: GeometryProxy) -> CGFloat {
        proxy.safeAreaInsets.top + 12
    }

    private func selectCard(_ card: StreakDashboardCard) {
        guard selectedCard != card else { return }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.86)) {
            selectedCard = card
        }
    }
}

private struct TopOpenStreakCardShape: Shape {
    let bottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(bottomCornerRadius, rect.width * 0.5, rect.height * 0.5)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - radius),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private enum StreakDashboardCard: CaseIterable, Identifiable {
    case top
    case middle
    case bottom

    var id: Self { self }
}

private struct FriendsTabView: View {
    let friends: [PrayerFriend]

    var body: some View {
        AppScreenScaffold {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amigos")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Uma base simples para a parte social que vem depois.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.92))
            }

            StitchedCard(pose: .centered, maxWidth: 390) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Em breve")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    Text("Aqui vai dar para acompanhar seus amigos, ver quem já fez a oração da manhã e mandar uma cutucada quando alguém falhar.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.68))
                        .lineSpacing(5)
                }
            }

            StitchedCard(pose: .centered, maxWidth: 390) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Seu círculo")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                        if index > 0 {
                            Divider()
                                .overlay(Color.black.opacity(0.08))
                        }

                        PrayerFriendRow(friend: friend)
                    }
                }
            }
        }
    }
}

private struct AppScreenScaffold<Content: View>: View {
    private let spacing: CGFloat
    @ViewBuilder private let content: Content

    init(spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .padding(24)
                .frame(maxWidth: 430, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct PrayerCompletionPopup: View {
    let particleCount: Int
    let layers: Set<PrayerCompletionParticle.Layer>
    let onClose: () -> Void
    private let particles: [PrayerCompletionParticle]

    init(
        particleCount: Int,
        layers: Set<PrayerCompletionParticle.Layer>,
        onClose: @escaping () -> Void
    ) {
        self.particleCount = particleCount
        self.layers = layers
        self.onClose = onClose
        self.particles = PrayerCompletionParticle.makeBatch(
            count: particleCount,
            allowedLayers: layers
        )
    }

    private var dismissAfter: Double {
        (particles.map { $0.delay + $0.duration }.max() ?? 0) + 0.6
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(particles) { particle in
                    PrayerCompletionParticleView(
                        particle: particle,
                        viewportSize: proxy.size
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task {
            guard !particles.isEmpty else { return }
            try? await Task.sleep(for: .seconds(dismissAfter))
            onClose()
        }
    }
}

private struct PrayerCompletionParticleView: View {
    let particle: PrayerCompletionParticle
    let viewportSize: CGSize

    @State private var progress: CGFloat = 0

    var body: some View {
        Text("🔥")
            .font(.system(size: particle.size))
            .blur(radius: particle.blurRadius)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(particle.opacity)
            .shadow(color: Color.orange.opacity(particle.glowOpacity), radius: particle.glowRadius)
            .position(x: xPosition, y: yPosition)
            .task {
                progress = 0
                try? await Task.sleep(for: .seconds(particle.delay))
                withAnimation(.linear(duration: particle.duration)) {
                    progress = 1
                }
            }
    }

    private var normalizedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    private var gravityProgress: CGFloat {
        CGFloat(pow(Double(normalizedProgress), 1.38))
    }

    private var xPosition: CGFloat {
        let baseX = lerp(
            viewportSize.width * particle.startX,
            viewportSize.width * particle.endX,
            gravityProgress
        )
        let swayAngle = (normalizedProgress * CGFloat.pi * particle.swayCycles) + particle.swayPhase
        let sway = CGFloat(sin(Double(swayAngle)))
            * particle.swayAmplitude
            * (1 - (normalizedProgress * 0.18))

        return baseX + sway
    }

    private var yPosition: CGFloat {
        let startY = particle.startYOffset
        let endY = viewportSize.height + particle.endYOffset
        return lerp(startY, endY, gravityProgress)
    }

    private var scale: CGFloat {
        lerp(particle.startScale, particle.endScale, normalizedProgress)
    }

    private var rotation: Double {
        particle.rotation * Double(normalizedProgress)
    }

    private func lerp<T: BinaryFloatingPoint>(_ start: T, _ end: T, _ progress: T) -> T {
        start + ((end - start) * progress)
    }
}

private struct PrayerCompletionParticle: Identifiable {
    enum Layer: Hashable {
        case nearFront
        case nearBack
        case midFront
        case midBack
        case far
    }

    let id = UUID()
    let layer: Layer
    let startX: CGFloat
    let endX: CGFloat
    let startYOffset: CGFloat
    let endYOffset: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let startScale: CGFloat
    let endScale: CGFloat
    let opacity: Double
    let blurRadius: CGFloat
    let glowRadius: CGFloat
    let glowOpacity: Double
    let swayAmplitude: CGFloat
    let swayCycles: CGFloat
    let swayPhase: CGFloat

    static func makeBatch(count: Int, allowedLayers: Set<Layer>) -> [PrayerCompletionParticle] {
        (0..<count).map { _ in
            let layer = randomLayer(from: allowedLayers)
            let startX = CGFloat.random(in: 0.08...0.92)
            let drift = CGFloat.random(in: -0.14...0.14)

            let sizeRange: ClosedRange<CGFloat>
            let startScaleRange: ClosedRange<CGFloat>
            let endScaleRange: ClosedRange<CGFloat>
            let opacityRange: ClosedRange<Double>
            let blurRange: ClosedRange<CGFloat>
            let glowRadiusRange: ClosedRange<CGFloat>
            let glowOpacityRange: ClosedRange<Double>
            let delayRange: ClosedRange<Double>
            let durationRange: ClosedRange<Double>
            let startYOffsetRange: ClosedRange<CGFloat>
            let endYOffsetRange: ClosedRange<CGFloat>
            let swayAmplitudeRange: ClosedRange<CGFloat>
            let swayCyclesRange: ClosedRange<CGFloat>

            switch layer {
            case .nearFront:
                sizeRange = 42...60
                startScaleRange = 0.92...1.02
                endScaleRange = 1.02...1.14
                opacityRange = 0.96...1.0
                blurRange = 0...0.3
                glowRadiusRange = 6...11
                glowOpacityRange = 0.18...0.28
                delayRange = 0...0.12
                durationRange = 2.0...2.8
                startYOffsetRange = -240 ... -80
                endYOffsetRange = 180 ... 320
                swayAmplitudeRange = 14 ... 24
                swayCyclesRange = 1.1 ... 1.8
            case .nearBack:
                sizeRange = 40...56
                startScaleRange = 0.88...0.98
                endScaleRange = 0.98...1.10
                opacityRange = 0.82...0.92
                blurRange = 0.8...1.8
                glowRadiusRange = 4...8
                glowOpacityRange = 0.08...0.16
                delayRange = 0.02...0.14
                durationRange = 2.1...2.9
                startYOffsetRange = -250 ... -90
                endYOffsetRange = 190 ... 330
                swayAmplitudeRange = 12 ... 20
                swayCyclesRange = 1.0 ... 1.7
            case .midFront:
                sizeRange = 30...46
                startScaleRange = 0.82...0.94
                endScaleRange = 0.94...1.06
                opacityRange = 0.80...0.90
                blurRange = 0.8...1.6
                glowRadiusRange = 4...8
                glowOpacityRange = 0.10...0.18
                delayRange = 0.04...0.18
                durationRange = 2.5...3.3
                startYOffsetRange = -280 ... -120
                endYOffsetRange = 220 ... 380
                swayAmplitudeRange = 10 ... 18
                swayCyclesRange = 1.0 ... 1.6
            case .midBack:
                sizeRange = 26...40
                startScaleRange = 0.78...0.90
                endScaleRange = 0.88...1.0
                opacityRange = 0.66...0.80
                blurRange = 1.4...2.4
                glowRadiusRange = 3...6
                glowOpacityRange = 0.06...0.12
                delayRange = 0.05...0.20
                durationRange = 2.7...3.5
                startYOffsetRange = -300 ... -140
                endYOffsetRange = 240 ... 400
                swayAmplitudeRange = 8 ... 14
                swayCyclesRange = 0.95 ... 1.45
            case .far:
                sizeRange = 22...34
                startScaleRange = 0.72...0.86
                endScaleRange = 0.82...0.96
                opacityRange = 0.56...0.72
                blurRange = 1.8...3.2
                glowRadiusRange = 2...5
                glowOpacityRange = 0.04...0.10
                delayRange = 0.06...0.18
                durationRange = 3.0...4.0
                startYOffsetRange = -320 ... -160
                endYOffsetRange = 260 ... 440
                swayAmplitudeRange = 6 ... 12
                swayCyclesRange = 0.9 ... 1.4
            }

            return PrayerCompletionParticle(
                layer: layer,
                startX: startX,
                endX: min(max(startX + drift, 0.04), 0.96),
                startYOffset: CGFloat.random(in: startYOffsetRange),
                endYOffset: CGFloat.random(in: endYOffsetRange),
                size: CGFloat.random(in: sizeRange),
                rotation: Double.random(in: -54 ... 54),
                delay: Double.random(in: delayRange),
                duration: Double.random(in: durationRange),
                startScale: CGFloat.random(in: startScaleRange),
                endScale: CGFloat.random(in: endScaleRange),
                opacity: Double.random(in: opacityRange),
                blurRadius: CGFloat.random(in: blurRange),
                glowRadius: CGFloat.random(in: glowRadiusRange),
                glowOpacity: Double.random(in: glowOpacityRange),
                swayAmplitude: CGFloat.random(in: swayAmplitudeRange),
                swayCycles: CGFloat.random(in: swayCyclesRange),
                swayPhase: CGFloat.random(in: 0 ... (CGFloat.pi * 2))
            )
        }
    }

    private static func randomLayer(from allowedLayers: Set<Layer>) -> Layer {
        let weightedLayers = [
            (Layer.nearFront, 0.15),
            (Layer.nearBack, 0.15),
            (Layer.midFront, 0.24),
            (Layer.midBack, 0.18),
            (Layer.far, 0.28),
        ].filter { allowedLayers.contains($0.0) }

        guard let fallback = weightedLayers.first?.0 else {
            return .nearFront
        }

        let totalWeight = weightedLayers.reduce(0.0) { $0 + $1.1 }
        var roll = Double.random(in: 0...totalWeight)

        for (layer, weight) in weightedLayers {
            roll -= weight
            if roll <= 0 {
                return layer
            }
        }

        return fallback
    }
}

private struct PrayerFriendRow: View {
    let friend: PrayerFriend

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(friend.badgeColor.opacity(0.20))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(friend.initials)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(friend.badgeColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(friend.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    Circle()
                        .fill(friend.badgeColor)
                        .frame(width: 8, height: 8)
                }

                Text(friend.statusText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.black.opacity(0.62))
                    .lineSpacing(4)
            }

            Spacer()

            Text("\(friend.streak) dias")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.black.opacity(0.62))
        }
    }
}

private struct PrayerFriend: Identifiable {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
