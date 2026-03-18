//
//  PrayerIdleHomeView.swift
//  OracaoDiaria
//
//  Created by Codex on 16/03/26.
//

import Foundation
import SwiftUI

struct PrayerIdleHomeView<Content: View>: View {
    @ObservedObject private var store: PrayerProgressStore
    private let showsAmbientBackground: Bool
    private let content: (Double) -> Content
    @State private var visualProgress: Double

    init(
        store: PrayerProgressStore,
        showsAmbientBackground: Bool = true,
        @ViewBuilder content: @escaping (Double) -> Content
    ) {
        self._store = ObservedObject(wrappedValue: store)
        self.showsAmbientBackground = showsAmbientBackground
        self.content = content
        self._visualProgress = State(initialValue: store.countdownProgress)
    }

    var body: some View {
        ZStack {
            if showsAmbientBackground {
                PrayerAmbientBackground(progress: visualProgress)
            }
            content(visualProgress)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onChange(of: store.countdownProgress) { oldValue, newValue in
            let animation: Animation

            if newValue < oldValue {
                animation = .easeOut(duration: 0.70)
            } else if store.isRunning {
                animation = .linear(duration: 1.0)
            } else {
                animation = .spring(response: 0.36, dampingFraction: 0.84)
            }

            withAnimation(animation) {
                visualProgress = newValue
            }
        }
    }
}

extension PrayerIdleHomeView where Content == EmptyView {
    init(store: PrayerProgressStore) {
        self.init(store: store, showsAmbientBackground: true) { _ in
            EmptyView()
        }
    }
}

private struct PrayerAmbientBackground: View {
    let progress: Double

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    backgroundTopColor,
                    backgroundMiddleColor,
                    backgroundBottomColor,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(primaryGlowColor)
                .frame(width: 420, height: 420)
                .blur(radius: 120)
                .offset(x: 124, y: -188)

            Circle()
                .fill(secondaryGlowColor)
                .frame(width: 300, height: 300)
                .blur(radius: 110)
                .offset(x: -92, y: -124)

            Ellipse()
                .fill(Color.white.opacity(0.06 + (normalizedProgress * 0.06)))
                .frame(width: 520, height: 210)
                .blur(radius: 92)
                .offset(x: 58, y: -188)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.30),
                    .clear,
                    Color.black.opacity(0.36 - (normalizedProgress * 0.18)),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var backgroundTopColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.02, 0.07, 0.09),
            to: SIMD3<Double>(0.80, 0.84, 0.82),
            progress: normalizedProgress
        )
    }

    private var backgroundMiddleColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.01, 0.05, 0.07),
            to: SIMD3<Double>(0.58, 0.66, 0.68),
            progress: normalizedProgress
        )
    }

    private var backgroundBottomColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.0, 0.0, 0.0),
            to: SIMD3<Double>(0.40, 0.44, 0.46),
            progress: normalizedProgress
        )
    }

    private var primaryGlowColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.06, 0.62, 0.72),
            to: SIMD3<Double>(0.62, 0.84, 0.88),
            progress: normalizedProgress
        )
        .opacity(0.86)
    }

    private var secondaryGlowColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.03, 0.22, 0.26),
            to: SIMD3<Double>(0.92, 0.84, 0.72),
            progress: normalizedProgress
        )
        .opacity(0.48)
    }

    private func interpolatedColor(
        from start: SIMD3<Double>,
        to end: SIMD3<Double>,
        progress: Double
    ) -> Color {
        let clampedProgress = min(max(progress, 0), 1)
        let mixed = start + ((end - start) * clampedProgress)
        return Color(red: mixed.x, green: mixed.y, blue: mixed.z)
    }
}

struct PrayerDurationTimerView: View {
    @ObservedObject var store: PrayerProgressStore
    let visualProgress: Double

    @State private var showsResetConfirmation = false
    @State private var dragStartMinutes: Int?
    @State private var lastDraggedMinutes: Int?
    @State private var dragOffset: CGFloat = 0
    @State private var sliderVisualProgress: CGFloat = 0
    @State private var separatorPulse = false

    private let pointsPerMinute: CGFloat = 18

    var body: some View {
        GeometryReader { _ in
            centeredContent
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert("Reiniciar timer?", isPresented: $showsResetConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Reiniciar", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.32)) {
                        store.resetPrayer()
                    }
                    triggerOnboardingHaptic(.medium)
                }
            } message: {
                Text("Isso apaga o progresso atual e volta o cronômetro para o tempo inicial.")
            }
        }
    }

    @ViewBuilder
    private var centeredContent: some View {
        VStack(spacing: 28) {
            timerDisplay
                .frame(maxWidth: .infinity, minHeight: 188)
                .contentShape(Rectangle())
                .offset(y: dragVisualOffset)
                .highPriorityGesture(durationAdjustmentGesture)
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            showsResetConfirmation = true
                            triggerOnboardingHaptic(.light)
                        }
                )
                .onAppear(perform: refreshSeparatorPulse)
                .onChange(of: store.isRunning) { _, _ in
                    refreshSeparatorPulse()
                }

            PrayerActionSlider(
                title: sliderTitle,
                emoji: sliderEmoji,
                progress: sliderVisualProgress,
                action: store.handleTimerInteraction
            )
            .frame(maxWidth: 360)
        }
        .frame(maxWidth: 430)
        .onAppear {
            sliderVisualProgress = initialSliderProgress
        }
        .onChange(of: normalizedVisualProgress) { oldValue, newValue in
            guard !store.isAwaitingConfirmation else { return }

            let animation: Animation
            if store.isRunning {
                animation = .linear(duration: 1.0)
            } else if newValue < oldValue {
                animation = .easeOut(duration: 0.32)
            } else {
                animation = .spring(response: 0.36, dampingFraction: 0.84)
            }

            withAnimation(animation) {
                sliderVisualProgress = CGFloat(newValue)
            }
        }
        .onChange(of: store.isAwaitingConfirmation) { _, newValue in
            guard newValue else { return }

            withAnimation(.easeInOut(duration: 0.52)) {
                sliderVisualProgress = 0
            }
        }
    }

    @ViewBuilder
    private var timerDisplay: some View {
        HStack(alignment: .bottom, spacing: 10) {
            timerDigits(
                timerMinutesText,
                size: 158,
                weight: .light,
                tracking: -7.2,
                color: timerPrimaryTextColor
            )

            VStack(alignment: .leading, spacing: -4) {
                Text(":")
                    .font(.system(size: 40, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.8)
                    .foregroundStyle(timerSmallUnitColor.opacity(timerSeparatorOpacity))
                    .scaleEffect(timerSeparatorScale)

                timerDigits(
                    timerSecondsText,
                    size: 46,
                    weight: .light,
                    tracking: -1.6,
                    color: timerSmallUnitColor
                )
            }
            .padding(.bottom, 24)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.46), value: visualProgress)
    }

    private var sliderTitle: String {
        if store.isAwaitingConfirmation {
            return "Deslize para concluir"
        }

        if store.isRunning {
            return "Deslize para pausar"
        }

        if store.remainingSeconds == store.defaultDurationSeconds {
            return "Deslize para iniciar"
        }

        return "Deslize para continuar"
    }

    private var sliderEmoji: String {
        if store.isAwaitingConfirmation {
            return "✅"
        }

        if store.isRunning {
            return "⏸️"
        }

        if store.remainingSeconds == store.defaultDurationSeconds {
            return "🙏"
        }

        return "🔁"
    }

    private var dragVisualOffset: CGFloat {
        store.canAdjustDuration ? dragOffset * 0.16 : 0
    }

    private var initialSliderProgress: CGFloat {
        store.isAwaitingConfirmation ? 0 : CGFloat(normalizedVisualProgress)
    }

    private var displayedSeconds: Int {
        store.isAwaitingConfirmation ? 0 : max(store.remainingSeconds, 0)
    }

    private var timerMinutesText: String {
        String(format: "%02d", displayedSeconds / 60)
    }

    private var timerSecondsText: String {
        String(format: "%02d", displayedSeconds % 60)
    }

    private var normalizedVisualProgress: Double {
        min(max(visualProgress, 0), 1)
    }

    private var timerPrimaryTextColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.98, 0.985, 1.0),
            to: SIMD3<Double>(0.10, 0.105, 0.12),
            progress: normalizedVisualProgress
        )
    }

    private var timerSmallUnitColor: Color {
        interpolatedColor(
            from: SIMD3<Double>(0.93, 0.95, 1.0),
            to: SIMD3<Double>(0.22, 0.24, 0.28),
            progress: normalizedVisualProgress
        )
    }

    private var timerSeparatorOpacity: Double {
        if store.isRunning {
            return separatorPulse ? 0.34 : 0.74
        }

        return visualProgress < 0.56 ? 0.56 : 0.42
    }

    private var timerSeparatorScale: CGFloat {
        store.isRunning && separatorPulse ? 0.96 : 1
    }

    private var durationAdjustmentGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard store.canAdjustDuration else { return }

                let startingMinutes = dragStartMinutes ?? store.preferredDurationMinutes
                let previousMinutes = lastDraggedMinutes ?? startingMinutes
                let deltaMinutes = Int((-value.translation.height / pointsPerMinute).rounded())
                let nextMinutes = min(max(startingMinutes + deltaMinutes, 1), 60)

                dragStartMinutes = startingMinutes
                dragOffset = value.translation.height

                guard nextMinutes != previousMinutes else { return }
                lastDraggedMinutes = nextMinutes
                store.updatePreferredDurationIfNeeded(nextMinutes)
                triggerOnboardingHaptic(.selection)
            }
            .onEnded { _ in
                dragStartMinutes = nil
                lastDraggedMinutes = nil
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    dragOffset = 0
                }
            }
    }

    @ViewBuilder
    private func timerDigits(
        _ text: String,
        size: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color
    ) -> some View {
        HStack(spacing: tracking) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                Text(String(character))
                    .font(.system(size: size, weight: weight, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .fixedSize(horizontal: true, vertical: false)
                    .contentTransition(.numericText())
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func refreshSeparatorPulse() {
        guard store.isRunning else {
            withAnimation(.easeOut(duration: 0.18)) {
                separatorPulse = false
            }
            return
        }

        separatorPulse = false
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                separatorPulse = true
            }
        }
    }

    private func interpolatedColor(
        from start: SIMD3<Double>,
        to end: SIMD3<Double>,
        progress: Double
    ) -> Color {
        let clampedProgress = min(max(progress, 0), 1)
        let mixed = start + ((end - start) * clampedProgress)
        return Color(red: mixed.x, green: mixed.y, blue: mixed.z)
    }
}

private struct PrayerActionSlider: View {
    let title: String
    let emoji: String
    let progress: CGFloat
    let action: () -> Void

    @State private var manualOffset: CGFloat?
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var interactionProgress: CGFloat = 0
    @State private var crossedUnlockThreshold = false

    var body: some View {
        GeometryReader { proxy in
            let knobSize: CGFloat = 60
            let horizontalPadding: CGFloat = 7
            let unlockThreshold: CGFloat = 0.84
            let maxOffset = max(proxy.size.width - knobSize - (horizontalPadding * 2), 1)
            let automaticProgress = min(max(progress, 0), 1)
            let automaticOffset = automaticProgress * maxOffset
            let resolvedOffset = min(max(manualOffset ?? automaticOffset, 0), maxOffset)
            let resolvedProgress = min(max(resolvedOffset / maxOffset, 0), 1)
            let easedProgress = Self.easeOutCubic(resolvedProgress)
            let stretchProgress = Self.stretchEnvelope(resolvedProgress) * interactionProgress
            let knobWidth = knobSize + (stretchProgress * 14)
            let knobHeight = knobSize - (stretchProgress * 2.8)
            let knobOffset = resolvedOffset + horizontalPadding
            let fillWidth = min(knobOffset + knobWidth, proxy.size.width - horizontalPadding)
            let knobVerticalOffset = ((knobSize - knobHeight) * 0.5) - (stretchProgress * 0.7)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.92))

                progressFill(width: fillWidth)

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.82 - (easedProgress * 0.18)))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 70)
                    .opacity(1.0 - (easedProgress * 0.24))

                knobView(
                    width: knobWidth,
                    height: knobHeight,
                    progress: resolvedProgress,
                    easedProgress: easedProgress,
                    stretchProgress: stretchProgress,
                    offsetX: knobOffset,
                    offsetY: knobVerticalOffset
                )
            }
            .padding(6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.08))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 16, x: 0, y: 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartOffset = resolvedOffset
                            manualOffset = resolvedOffset
                            withAnimation(.easeOut(duration: 0.18)) {
                                interactionProgress = 1
                            }
                        }

                        let nextOffset = min(max(dragStartOffset + value.translation.width, 0), maxOffset)
                        manualOffset = nextOffset

                        let nextProgress = min(max(nextOffset / maxOffset, 0), 1)
                        let isPastUnlockThreshold = nextProgress >= unlockThreshold
                        if isPastUnlockThreshold != crossedUnlockThreshold {
                            crossedUnlockThreshold = isPastUnlockThreshold
                            triggerOnboardingHaptic(isPastUnlockThreshold ? .light : .selection)
                        }
                    }
                    .onEnded { value in
                        let currentOffset = min(max(manualOffset ?? automaticOffset, 0), maxOffset)
                        let predictedOffset = min(max(dragStartOffset + (value.predictedEndTranslation.width * 0.92), 0), maxOffset)
                        let projectedOffset = max(currentOffset, predictedOffset)
                        let didUnlock = projectedOffset > maxOffset * unlockThreshold
                        isDragging = false
                        crossedUnlockThreshold = false

                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            interactionProgress = 0
                        }

                        if didUnlock {
                            triggerOnboardingHaptic(.medium)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                manualOffset = maxOffset
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
                                action()
                                withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                                    manualOffset = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                                    manualOffset = nil
                                }
                            }
                        } else {
                            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.82, blendDuration: 0.12)) {
                                manualOffset = automaticOffset
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                                manualOffset = nil
                            }
                        }
                    }
            )
        }
        .frame(height: 78)
    }

    private static func easeOutCubic(_ value: CGFloat) -> CGFloat {
        let clampedValue = min(max(value, 0), 1)
        let inverse = 1 - clampedValue
        return 1 - (inverse * inverse * inverse)
    }

    private static func stretchEnvelope(_ progress: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 1)
        let normalizedProgress = min(clampedProgress / 0.92, 1)
        return max(sin(normalizedProgress * .pi), 0)
    }

    @ViewBuilder
    private func progressFill(width: CGFloat) -> some View {
        let fillGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.white.opacity(0.02),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        Capsule(style: .continuous)
            .fill(fillGradient)
            .frame(width: width)
    }

    @ViewBuilder
    private func knobView(
        width: CGFloat,
        height: CGFloat,
        progress: CGFloat,
        easedProgress: CGFloat,
        stretchProgress: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> some View {
        let knobGradient = LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.16, blue: 0.18),
                Color(red: 0.08, green: 0.08, blue: 0.10),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let shineGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.16 + (stretchProgress * 0.05)),
                Color.white.opacity(0.02),
                .clear,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let shadowRadius = 12 + (stretchProgress * 6)
        let shadowOffsetY = 7 + (stretchProgress * 2)

        Capsule(style: .continuous)
            .fill(knobGradient)
            .frame(width: width, height: height)
            .overlay(
                Capsule(style: .continuous)
                    .fill(shineGradient)
                    .padding(1.2)
            )
            .overlay(
                Text(emoji)
                    .font(.system(size: 24))
                    .rotationEffect(.degrees(progress * 720))
                    .scaleEffect(1 + (stretchProgress * 0.03))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.34), lineWidth: 1)
            )
            .offset(x: offsetX, y: offsetY)
            .shadow(color: Color.black.opacity(0.28), radius: shadowRadius, x: 0, y: shadowOffsetY)
    }
}

struct PrayerIdleHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let store = PrayerProgressStore()

        ZStack {
            Color.black
                .ignoresSafeArea()

            PrayerDurationTimerView(
                store: store,
                visualProgress: 0
            )
        }
        .previewDevice("iPhone 16 Pro")
    }
}
