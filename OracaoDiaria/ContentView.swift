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
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    StreakTabView(store: prayerProgress)
                        .tabItem {
                            Label("Streak", systemImage: "flame.fill")
                        }
                        .tag(MainAppTab.streak)

                    PrayerTimerHomeView()
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

                if selectedTab == .orar {
                    PrayerStartAccessoryButton(
                        title: "Iniciar Minha Oração 🙏🏻",
                        action: prayerProgress.handlePrimaryAction
                    )
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 64)
                    .zIndex(2)
                }

                if prayerProgress.showsCompletionPopup {
                    PrayerCompletionPopup {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            prayerProgress.dismissCompletionPopup()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(10)
                }
            }
        }
        .onChange(of: selectedTab) {
            triggerOnboardingHaptic(.selection)
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            prayerProgress.refreshFromClock()
        }
        .animation(.easeInOut(duration: 0.28), value: prayerProgress.showsCompletionPopup)
    }
}

private struct PrayerTimerHomeView: View {
    var body: some View {
        PrayerIdleHomeView()
    }
}

private struct StreakTabView: View {
    @ObservedObject var store: PrayerProgressStore

    private let weekdaySymbols = ["S", "T", "Q", "Q", "S", "S", "D"]

    var body: some View {
        AppScreenScaffold {
            VStack(alignment: .leading, spacing: 8) {
                Text("Streak")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Veja os dias do mês em que sua oração foi feita.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.92))
            }

            StitchedCard(pose: .centered, maxWidth: 390) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        SummaryPill(
                            emoji: "🔥",
                            title: "Atual",
                            value: "\(store.streakCount) \(store.streakCount == 1 ? "dia" : "dias")"
                        )

                        SummaryPill(
                            emoji: store.prayedToday ? "✅" : "🕊️",
                            title: "Hoje",
                            value: store.prayedToday ? "feito" : "em aberto"
                        )
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(store.currentMonthTitle)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)

                            Spacer()

                            Text("\(store.monthlyPrayerCount) dias marcados")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.black.opacity(0.62))
                        }

                        HStack {
                            ForEach(weekdaySymbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.black.opacity(0.45))
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            ForEach(Array(store.monthCells.enumerated()), id: \.offset) { _, date in
                                PrayerDayCell(
                                    date: date,
                                    isCompleted: date.map { store.hasCompletedPrayer(on: $0) } ?? false,
                                    isToday: date.map(store.isToday(_:)) ?? false
                                )
                            }
                        }
                    }
                }
            }
        }
    }
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

private struct SlideToConfirmButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let knobSize: CGFloat = 56
            let horizontalPadding: CGFloat = 6
            let maxOffset = max(proxy.size.width - knobSize - (horizontalPadding * 2), 1)
            let progress = min(max(dragOffset / maxOffset, 0), 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.08))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.90, green: 0.95, blue: 1.0))
                    .frame(width: knobSize + dragOffset + horizontalPadding)

                HStack {
                    Spacer()

                    Label(title, systemImage: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.55 + (progress * 0.25)))
                        .opacity(1.0 - (progress * 0.35))
                        .padding(.horizontal, 22)
                }

                Circle()
                    .fill(Color.black)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Image(systemName: icon)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: dragOffset + horizontalPadding)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            }
            .frame(height: 68)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragOffset = min(max(value.translation.width, 0), maxOffset)
                    }
                    .onEnded { _ in
                        let didUnlock = dragOffset > maxOffset * 0.84

                        if didUnlock {
                            withAnimation(.easeOut(duration: 0.18)) {
                                dragOffset = maxOffset
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                action()
                                dragOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 68)
    }
}

private struct PrayerCompletionPopup: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🔥")
                    .font(.system(size: 76))

                Text("Mais um dia firme.")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)

                Text("“Todo atleta em tudo se domina.”")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)

                Text("1 Coríntios 9:25")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.58))

                Button("Continuar", action: onClose)
                    .buttonStyle(.plain)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.90, green: 0.95, blue: 1.0))
                    )
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
            .padding(24)
        }
        .task {
            try? await Task.sleep(for: .seconds(2.6))
            onClose()
        }
    }
}

private struct SummaryPill: View {
    let emoji: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(emoji) \(title)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.black.opacity(0.7))

            Text(value)
                .font(.headline.weight(.heavy))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.95, green: 0.97, blue: 1.0))
        )
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

private struct PrayerDayCell: View {
    let date: Date?
    let isCompleted: Bool
    let isToday: Bool

    var body: some View {
        Group {
            if let date {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(backgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: isToday ? 1.5 : 0)
                    )
            } else {
                Color.clear
                    .frame(height: 38)
            }
        }
    }

    private var backgroundColor: Color {
        if isCompleted {
            return Color(red: 0.87, green: 0.93, blue: 1.0)
        }

        if isToday {
            return Color.white.opacity(0.92)
        }

        return Color.black.opacity(0.04)
    }

    private var borderColor: Color {
        isToday ? Color(red: 0.29, green: 0.57, blue: 0.92) : .clear
    }

    private var textColor: Color {
        isCompleted ? Color.black : Color.black.opacity(0.65)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
