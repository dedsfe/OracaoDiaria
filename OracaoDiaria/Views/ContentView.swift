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
    @State private var selectedTab: MainAppTab = .streak

    private let friends = PrayerFriend.samples

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                StreakTabView(store: prayerProgress) {
                    selectedTab = .friends
                }
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

            if selectedTab == .orar, prayerProgress.showsCompletionPopup {
                PrayerCompletionPopup(
                    prayedDurationText: prayerProgress.completedPrayerDurationText,
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

            if selectedTab != .orar, prayerProgress.showsCompletionPopup {
                prayerProgress.dismissCompletionPopup()
            }
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
            selectedTab = .streak
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
                        prayedDurationText: store.completedPrayerDurationText,
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
    @AppStorage("savedUserName") private var savedUserName = ""
    @ObservedObject var store: PrayerProgressStore
    let onOpenFriends: () -> Void
    @State private var showsStreakPopup = false
    private let previewFriends: [StreakPreviewFriend] = [
        StreakPreviewFriend(
            id: "friend-1",
            emoji: "👩🏽",
            colors: [Color(red: 0.98, green: 0.84, blue: 0.88), Color(red: 0.94, green: 0.72, blue: 0.82)]
        ),
        StreakPreviewFriend(
            id: "friend-2",
            emoji: "👦🏻",
            colors: [Color(red: 0.97, green: 0.86, blue: 0.72), Color(red: 0.95, green: 0.78, blue: 0.61)]
        ),
        StreakPreviewFriend(
            id: "friend-3",
            emoji: "👱🏻‍♀️",
            colors: [Color(red: 0.99, green: 0.86, blue: 0.90), Color(red: 0.97, green: 0.78, blue: 0.84)]
        ),
        StreakPreviewFriend(
            id: "friend-4",
            emoji: "👨🏾",
            colors: [Color(red: 0.79, green: 0.88, blue: 0.98), Color(red: 0.70, green: 0.82, blue: 0.96)]
        ),
    ]

    var body: some View {
        ZStack {
            AppScreenScaffold(spacing: 22) {
                VStack(spacing: 10) {
                    Text("Olá, \(displayName)!")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(headerSubtitle)
                        .font(.system(size: 23, weight: .light))
                        .foregroundStyle(.white.opacity(0.98))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 0)
                .padding(.bottom, 8)

                Button {
                    triggerOnboardingHaptic(.light)
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                        showsStreakPopup = true
                    }
                } label: {
                    StreakWeekCard(days: weekDays)
                        .frame(maxWidth: 338)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                StreakQuoteCard(
                    quote: selectedVerse.text,
                    reference: selectedVerse.reference
                )
                .frame(maxWidth: 338)
                .frame(maxWidth: .infinity)

                Button {
                    triggerOnboardingHaptic(.selection)
                    onOpenFriends()
                } label: {
                    StreakFriendsCard(
                        title: "Veja como seus amigos\nestão indo!",
                        friends: previewFriends
                    )
                    .frame(maxWidth: 338)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 372)
            .allowsHitTesting(!showsStreakPopup)

            if showsStreakPopup {
                StreakCalendarPopup(
                    store: store
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                        showsStreakPopup = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: showsStreakPopup)
    }

    private var displayName: String {
        let trimmed = savedUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Seu Nome" : trimmed
    }

    private var headerSubtitle: String {
        let messages = store.prayedToday
            ? StreakHomeContentCatalog.completedMessages
            : StreakHomeContentCatalog.pendingMessages
        return monthlyUniqueItem(from: messages, offset: store.prayedToday ? 0 : 11)
    }

    private var selectedVerse: StreakHomeVerse {
        monthlyUniqueItem(from: StreakHomeContentCatalog.verses, offset: 23)
    }

    private var weekDays: [StreakPreviewDay] {
        store.currentWeekDays.map { day in
            makePreviewDay(from: day, label: day.label)
        }
    }

    private func makePreviewDay(
        from day: PrayerProgressStore.WeeklyStreakDay,
        label: String
    ) -> StreakPreviewDay {
        let state: StreakPreviewDay.State
        switch day.state {
        case .completed:
            state = .completed
        case .todayCompleted:
            state = .currentCompleted
        case .todayPending:
            state = .currentPending
        case .empty:
            state = .pending
        }

        return StreakPreviewDay(
            id: day.id,
            label: label,
            state: state
        )
    }

    private func monthlyUniqueItem<T>(from items: [T], offset: Int) -> T {
        precondition(!items.isEmpty, "Expected non-empty content catalog.")

        let calendar = Calendar.current
        let today = Date()
        let dayIndex = max(calendar.component(.day, from: today) - 1, 0)
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)
        let nameSeed = displayName.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let startIndex = abs(nameSeed + (month * 17) + year + offset) % items.count
        let index = (startIndex + dayIndex) % items.count
        return items[index]
    }
}

private struct StreakCalendarPopup: View {
    @ObservedObject var store: PrayerProgressStore
    let onClose: () -> Void
    @State private var selectedMonthIndex = 12

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.14))
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 14) {
                TabView(selection: $selectedMonthIndex) {
                    ForEach(Array(calendarMonths.enumerated()), id: \.offset) { index, monthDate in
                        StreakMonthCalendarPage(
                            monthDate: monthDate,
                            dots: store.monthDots(for: monthDate),
                            store: store
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: selectedMonthHeight)
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 24)
        }
    }

    private var calendarMonths: [Date] {
        let calendar = Calendar.current
        let startOfCurrentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return (-12...12).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: startOfCurrentMonth)
        }
    }

    private var selectedMonthHeight: CGFloat {
        let clampedIndex = min(max(selectedMonthIndex, 0), calendarMonths.count - 1)
        let monthDate = calendarMonths[clampedIndex]
        let rowCount = max(store.monthDots(for: monthDate).count / 7, 5)
        return rowCount >= 6 ? 374 : 340
    }
}

private struct StreakMonthCalendarPage: View {
    let monthDate: Date
    let dots: [PrayerProgressStore.MonthlyPrayerDot]
    @ObservedObject var store: PrayerProgressStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekLabels = ["S", "T", "Q", "Q", "S", "S", "D"]

    var body: some View {
        VStack(spacing: 12) {
            Text(monthTitle)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.92))

            HStack(spacing: 8) {
                ForEach(weekLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.36))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dots) { dot in
                    StreakCalendarDayCell(dot: dot, store: store)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.98))
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthDate).capitalized
    }
}

private struct StreakCalendarDayCell: View {
    let dot: PrayerProgressStore.MonthlyPrayerDot
    @ObservedObject var store: PrayerProgressStore

    var body: some View {
        Group {
            if let date = dot.date {
                ZStack {
                    Circle()
                        .fill(backgroundFill)

                    if isCompleted {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.15, green: 0.85, blue: 0.21),
                                            Color(red: 0.03, green: 0.68, blue: 0.12),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 20, height: 22)
                    } else {
                        Text(dayNumber)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.92))
                    }
                }
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1.2)
                )
            } else {
                Color.clear
                    .frame(width: 34, height: 34)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dayNumber: String {
        guard let date = dot.date else { return "" }
        return String(Calendar.current.component(.day, from: date))
    }

    private var isCompleted: Bool {
        guard let date = dot.date else { return false }
        return store.hasCompletedPrayer(on: date)
    }

    private var isToday: Bool {
        guard let date = dot.date else { return false }
        return store.isToday(date)
    }

    private var backgroundFill: LinearGradient {
        if isToday {
            return LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.97, blue: 1.0),
                    Color.white.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(0.98),
                Color.white.opacity(0.98),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var borderColor: Color {
        isToday
            ? Color(red: 0.17, green: 0.62, blue: 0.95)
            : Color(red: 0.68, green: 0.86, blue: 0.98)
    }
}

private struct StreakPreviewDay: Identifiable {
    enum State {
        case completed
        case currentCompleted
        case currentPending
        case pending
    }

    let id: String
    let label: String
    let state: State
}

private struct StreakPreviewFriend: Identifiable {
    let id: String
    let emoji: String
    let colors: [Color]
}

private struct StreakWeekCard: View {
    let days: [StreakPreviewDay]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.63, green: 0.77, blue: 0.93).opacity(0.82),
                            Color(red: 0.52, green: 0.71, blue: 0.91).opacity(0.56),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .padding(10)

            HStack(spacing: 6) {
                ForEach(days) { day in
                    StreakWeekDayBadge(day: day)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .frame(height: 88)
        .shadow(color: Color(red: 0.27, green: 0.51, blue: 0.81).opacity(0.28), radius: 18, x: 0, y: 10)
    }
}

private struct StreakWeekDayBadge: View {
    let day: StreakPreviewDay

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundFill)

            if isCompleted {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.85, blue: 0.21),
                                    Color(red: 0.03, green: 0.68, blue: 0.12),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.34), lineWidth: 1)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 20, height: 22)
                .shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 2)
            } else {
                Text(day.label)
                    .font(.system(size: labelFontSize, weight: .regular))
                    .foregroundStyle(.black.opacity(0.95))
            }
        }
        .frame(width: 38, height: 38)
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: 1.4)
        )
        .shadow(color: day.state == .currentCompleted ? Color(red: 0.26, green: 0.63, blue: 0.93).opacity(0.20) : .clear, radius: 9, x: 0, y: 4)
    }

    private var isCompleted: Bool {
        day.state == .completed || day.state == .currentCompleted
    }

    private var labelFontSize: CGFloat {
        day.label.count > 1 ? 14 : 18
    }

    private var backgroundFill: LinearGradient {
        switch day.state {
        case .currentCompleted:
            return LinearGradient(
                colors: [
                    Color(red: 0.47, green: 0.79, blue: 1.0),
                    Color(red: 0.29, green: 0.67, blue: 0.95),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .currentPending:
            return LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.97, blue: 1.0),
                    Color.white.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .completed, .pending:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color.white.opacity(0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderColor: Color {
        switch day.state {
        case .currentCompleted, .currentPending:
            return Color(red: 0.17, green: 0.62, blue: 0.95)
        case .completed, .pending:
            return Color(red: 0.68, green: 0.86, blue: 0.98)
        }
    }
}

private struct StreakQuoteCard: View {
    let quote: String
    let reference: String

    var body: some View {
        VStack(spacing: 24) {
            Text(quote)
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(reference)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black.opacity(0.90))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white.opacity(0.97))
        )
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

private struct StreakFriendsCard: View {
    let title: String
    let friends: [StreakPreviewFriend]

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            HStack(spacing: -12) {
                ForEach(friends) { friend in
                    StreakFriendAvatar(friend: friend)
                }
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white.opacity(0.97))
        )
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

private struct StreakFriendAvatar: View {
    let friend: StreakPreviewFriend

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: friend.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(friend.emoji)
                .font(.system(size: 34))
        }
        .frame(width: 64, height: 64)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.92), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
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

private struct PrayerCompletionPopup: View {
    let prayedDurationText: String
    let particleCount: Int
    let layers: Set<PrayerCompletionParticle.Layer>
    let onClose: () -> Void
    private let particles: [PrayerCompletionParticle]

    init(
        prayedDurationText: String,
        particleCount: Int,
        layers: Set<PrayerCompletionParticle.Layer>,
        onClose: @escaping () -> Void
    ) {
        self.prayedDurationText = prayedDurationText
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

                VStack(spacing: 10) {
                    Text("Oração concluída")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))

                    Text(prayedDurationText)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Text("Tempo total em oração")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.64))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 30, x: 0, y: 16)
                .padding(.horizontal, 28)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
