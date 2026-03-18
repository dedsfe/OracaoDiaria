//
//  OnboardingFlowView.swift
//  OracaoDiaria
//
//  Created by Codex on 14/03/26.
//

import Foundation
import FamilyControls
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingFlowView: View {
    private let maxContentWidth: CGFloat = 430
    @Binding var didCompleteOnboarding: Bool
    @Binding var savedName: String
    private let showsLayoutDebug: Bool

    @StateObject private var viewModel: OnboardingViewModel
    @State private var immersiveStepCompletion: Set<Int> = []
    @State private var immersiveStepProgress: [Int: Double] = [:]

    @MainActor
    init(
        didCompleteOnboarding: Binding<Bool>,
        savedName: Binding<String>,
        showsLayoutDebug: Bool = false
    ) {
        self._didCompleteOnboarding = didCompleteOnboarding
        self._savedName = savedName
        self.showsLayoutDebug = showsLayoutDebug
        let screenTimeAccess = ScreenTimeAccessController()
        let notificationAccess = NotificationAccessController()
        self._viewModel = StateObject(
            wrappedValue: OnboardingViewModel(
                screenTimeAccess: screenTimeAccess,
                notificationAccess: notificationAccess
            )
        )
    }

    var body: some View {
        let horizontalInset = viewModel.isIntroStep ? 20.0 : 24.0
#if canImport(UIKit)
        let maxColumnWidth = min(self.maxContentWidth, UIScreen.main.bounds.width - (horizontalInset * 2))
#else
        let maxColumnWidth = self.maxContentWidth
#endif

        ZStack(alignment: .topLeading) {
            if viewModel.isIntroStep {
                Color.black
                    .ignoresSafeArea()
            } else {
                OnboardingBackground()
            }

            VStack(alignment: .leading, spacing: 16) {
                if viewModel.showsProgressHeader && !requiresImmersiveCompletion(for: viewModel.stepIndex) {
                    progressHeader
                }

                ZStack(alignment: .topLeading) {
                    currentStepView
                        .id(viewModel.stepIndex)
                        .transition(stepTransition)
                }
                .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity, alignment: Alignment.topLeading)

                if viewModel.showsGlobalNavigation {
                    navigationButtons
                }
            }
            .frame(maxWidth: maxColumnWidth, maxHeight: CGFloat.infinity, alignment: Alignment.topLeading)
            .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity, alignment: Alignment.top)
            .padding(.horizontal, horizontalInset)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .allowsHitTesting(!viewModel.showsCommitmentCelebration)

            if viewModel.showsCommitmentCelebration {
                CommitmentCelebrationView {
                    Task {
                        let completedName = await viewModel.completeOnboarding()
                        await MainActor.run {
                            savedName = completedName
                            didCompleteOnboarding = true
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.stepIndex {
        case 0:
            Step1HookView {
                triggerOnboardingHaptic(.medium)
                viewModel.goForward()
            }
        case 1:
            Step2ProblemView(
                isComplete: immersiveCompletionBinding(for: 1),
                progress: immersiveProgressBinding(for: 1)
            )
        case 2:
            Step3PromiseView(
                isComplete: immersiveCompletionBinding(for: 2),
                progress: immersiveProgressBinding(for: 2)
            )
        case 3:
            Step3NameView(
                data: $viewModel.data,
                isComplete: immersiveCompletionBinding(for: 3),
                progress: immersiveProgressBinding(for: 3)
            )
        case 4:
            Step4AgeView(
                data: $viewModel.data,
                isComplete: immersiveCompletionBinding(for: 4),
                progress: immersiveProgressBinding(for: 4)
            )
        case 5:
            Step5PhoneUsageView(
                screenTimeAccess: viewModel.screenTimeAccess,
                isComplete: immersiveCompletionBinding(for: 5),
                progress: immersiveProgressBinding(for: 5)
            )
        case 6:
            AnalyzeProfileScreen {
                viewModel.goForward()
            }
        case 7:
            Step6ImpactView(
                data: $viewModel.data,
                snapshot: viewModel.screenTimeAccess.latestSnapshot
            ) {
                viewModel.goForward()
            }
        case 8:
            Step7GoalsView(data: $viewModel.data)
        case 9:
            Step8VisionView(data: $viewModel.data)
        case 10:
            Step9WakeUpView(data: $viewModel.data)
        case 11:
            Step10PrayerDurationView(data: $viewModel.data)
        case 12:
            Step11BlockingAppsView(data: $viewModel.data)
        case 13:
            Step12ReminderView(
                data: $viewModel.data,
                notificationAccess: viewModel.notificationAccess
            )
        default:
            Step13ClosingView(data: $viewModel.data)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Spacer()

                Text("\(Int((headerProgressValue * 100).rounded()))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.68))
                    Capsule()
                        .fill(Color.white)
                        .frame(width: proxy.size.width * max(headerProgressValue, 0.02))
                }
            }
            .frame(height: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: headerProgressValue)
        .animation(.spring(response: 0.45, dampingFraction: 0.84), value: viewModel.stepIndex)
    }

    private var stepTransition: AnyTransition {
        switch viewModel.navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .trailing)),
                removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .leading))
            )
        case .backward:
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .leading)),
                removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .trailing))
            )
        }
    }

    private var navigationButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.stepIndex > 0 {
                Button("Voltar") {
                    triggerOnboardingHaptic(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        viewModel.goBack()
                    }
                }
                .buttonStyle(SecondaryOnboardingButtonStyle())
            }

            if shouldShowContinueButton {
                Button {
                    dismissKeyboard()
                    if viewModel.isFinalStep {
                        prewarmCommitmentCelebrationAssets()
                    }
                    triggerOnboardingHaptic(viewModel.isFinalStep ? .success : .medium)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                        viewModel.handlePrimaryAction()
                    }
                } label: {
                    if viewModel.isFinalStep {
                        HStack(spacing: 12) {
                            Text("👊🏻")
                            Text("Vamos nessa")
                        }
                    } else {
                        Text("Continuar")
                    }
                }
                .buttonStyle(PrimaryOnboardingButtonStyle())
                .disabled(!canProceedInCurrentStep)
                .opacity(canProceedInCurrentStep ? 1 : 0.45)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var canProceedInCurrentStep: Bool {
        viewModel.canProceed && (
            !requiresImmersiveCompletion(for: viewModel.stepIndex) ||
            immersiveStepCompletion.contains(viewModel.stepIndex)
        )
    }

    private var shouldShowContinueButton: Bool {
        !requiresImmersiveCompletion(for: viewModel.stepIndex) ||
        immersiveStepCompletion.contains(viewModel.stepIndex)
    }

    private var headerProgressValue: Double {
        if requiresImmersiveCompletion(for: viewModel.stepIndex) {
            return immersiveStepProgress[viewModel.stepIndex] ?? 0
        }

        return viewModel.progressValue
    }

    private func requiresImmersiveCompletion(for stepIndex: Int) -> Bool {
        (1...5).contains(stepIndex)
    }

    private func immersiveCompletionBinding(for stepIndex: Int) -> Binding<Bool> {
        Binding(
            get: { immersiveStepCompletion.contains(stepIndex) },
            set: { isComplete in
                if isComplete {
                    immersiveStepCompletion.insert(stepIndex)
                } else {
                    immersiveStepCompletion.remove(stepIndex)
                }
            }
        )
    }

    private func immersiveProgressBinding(for stepIndex: Int) -> Binding<Double> {
        Binding(
            get: { immersiveStepProgress[stepIndex] ?? 0 },
            set: { progress in
                immersiveStepProgress[stepIndex] = progress
            }
        )
    }

    private func dismissKeyboard() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
#endif
    }

}

private struct Step1HookView: View {
    let onStart: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 0)

                if OnboardingIntroMediaView.hasBundledVideo {
                    OnboardingIntroMediaView()
                        .frame(height: min(proxy.size.height * 0.56, 360))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Seja bem-vindo")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Comece sua manhã mais perto de Deus. ☀️")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.86))
                }

                Button("Começar") {
                    onStart()
                }
                .buttonStyle(PrimaryOnboardingButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 8)
        }
    }
}

private let immersiveSceneCoordinateSpace = "immersiveOnboardingScene"
private let immersiveCardMaxWidth: CGFloat = 360

private struct ImmersiveSceneStep<Content: View>: View {
    let pageCount: Int
    @Binding var isComplete: Bool
    @Binding var progress: Double
    @ViewBuilder let content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            let viewportHeight = proxy.size.height

            ZStack(alignment: .top) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        content(viewportHeight)
                    }
                    .scrollTargetLayout()
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: immersiveSceneCoordinateSpace)
                .scrollClipDisabled()
                .scrollBounceBehavior(.basedOnSize)
                .scrollTargetBehavior(.paging)
                .onPreferenceChange(ImmersiveSceneBlockFramePreferenceKey.self) { frames in
                    progress = completionProgress(blockFrames: frames, viewportHeight: viewportHeight)
                }

                PullDownHintBadge()
                    .padding(.top, 6)
                    .allowsHitTesting(false)
            }
        }
    }

    private func completionProgress(
        blockFrames: [Int: CGRect],
        viewportHeight: CGFloat
    ) -> Double {
        guard pageCount > 1 else { return 1 }

        guard
            let firstFrame = blockFrames[0],
            let lastFrame = blockFrames[pageCount - 1]
        else {
            return 0
        }

        let focusPoint = viewportHeight * 0.50
        let totalDistance = max(firstFrame.midY - lastFrame.midY, 1)
        let traveledDistance = firstFrame.midY - focusPoint
        return min(max(traveledDistance / totalDistance, 0), 1)
    }
}

private struct ImmersiveSceneBlockFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct ImmersiveSceneBlock<Content: View>: View {
    let index: Int
    let viewportHeight: CGFloat
    let minHeightFactor: CGFloat
    let alignment: Alignment
    let onFocusLock: (() -> Void)?
    @ViewBuilder private let content: Content
    @State private var hasTriggeredFocusLock = false

    init(
        index: Int,
        viewportHeight: CGFloat,
        minHeightFactor: CGFloat = 0.30,
        alignment: Alignment = .leading,
        onFocusLock: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.viewportHeight = viewportHeight
        self.minHeightFactor = minHeightFactor
        self.alignment = alignment
        self.onFocusLock = onFocusLock
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let progress = revealProgress(for: proxy.frame(in: .named(immersiveSceneCoordinateSpace)))
            let isFocusLocked = progress >= 0.999

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: horizontalAlignment)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(0.08 + (progress * 0.92))
            .blur(radius: 8 * (1 - progress))
            .scaleEffect(0.97 + (progress * 0.03))
            .offset(y: 16 * (1 - progress))
            .animation(.easeOut(duration: 0.16), value: progress)
            .onAppear {
                guard isFocusLocked, !hasTriggeredFocusLock else { return }
                hasTriggeredFocusLock = true
                onFocusLock?()
            }
            .onChange(of: isFocusLocked) { _, locked in
                guard locked, !hasTriggeredFocusLock else { return }
                hasTriggeredFocusLock = true
                onFocusLock?()
            }
            .background(
                Color.clear.preference(
                    key: ImmersiveSceneBlockFramePreferenceKey.self,
                    value: [index: proxy.frame(in: .named(immersiveSceneCoordinateSpace))]
                )
            )
        }
        .frame(minHeight: max(viewportHeight - 12, viewportHeight * max(minHeightFactor, 0.96)))
        .padding(.vertical, 0)
    }

    private func revealProgress(for frame: CGRect) -> Double {
        let focusPoint = viewportHeight * 0.50
        let distance = abs(frame.midY - focusPoint)
        let focusDeadZone = viewportHeight * 0.13

        if distance <= focusDeadZone {
            return 1
        }

        let normalized = min(
            max((distance - focusDeadZone) / (viewportHeight * 0.35), 0),
            1
        )
        return pow(1 - normalized, 1.1)
    }

    private var horizontalAlignment: Alignment {
        switch alignment {
        case .center:
            return .center
        default:
            return .leading
        }
    }
}

private struct ImmersiveSceneCopyText: View {
    let text: String
    var weight: Font.Weight = .semibold
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(.system(size: 29, weight: weight, design: .rounded))
            .foregroundStyle(.white.opacity(0.94))
            .lineSpacing(12)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Step2ProblemView: View {
    @Binding var isComplete: Bool
    @Binding var progress: Double

    var body: some View {
        ImmersiveSceneStep(pageCount: 8, isComplete: $isComplete, progress: $progress) { viewportHeight in
            ImmersiveSceneBlock(index: 0, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "Todos os meus dias começavam do mesmo jeito.")
            }

            ImmersiveSceneBlock(index: 1, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "📱 Eu pegava o celular sem nem pensar. Abria mensagens, via minhas redes sociais e coisas do trabalho.")
            }

            ImmersiveSceneBlock(index: 2, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Quando eu percebia, já tinha visto mil reels e nada de falar com Deus.")
            }

            ImmersiveSceneBlock(index: 3, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "🙏 Eu sempre me cobrava, porque o momento da manhã deveria ser meu e de Deus.")
            }

            ImmersiveSceneBlock(index: 4, viewportHeight: viewportHeight, minHeightFactor: 0.18) {
                ImmersiveSceneCopyText(text: "E isso pesava muito.", weight: .bold)
            }

            ImmersiveSceneBlock(index: 5, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "Todas as noites eu me cobrava e falava que na manhã seguinte ia mudar.")
            }

            ImmersiveSceneBlock(index: 6, viewportHeight: viewportHeight, minHeightFactor: 0.18) {
                ImmersiveSceneCopyText(text: "Mas nada mudava...")
            }

            ImmersiveSceneBlock(
                index: 7,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.26,
                alignment: .center,
                onFocusLock: {
                    guard !isComplete else { return }
                    isComplete = true
                    triggerOnboardingHaptic(.light)
                }
            ) {
                StitchedCard(pose: .hero, maxWidth: immersiveCardMaxWidth) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Foi aí que tive a ideia que mudou minha vida. ✨")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Text("Colocar Deus antes do scroll, pelo menos no primeiro contato do meu dia.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.76))
                            .lineSpacing(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct Step3PromiseView: View {
    @Binding var isComplete: Bool
    @Binding var progress: Double

    var body: some View {
        ImmersiveSceneStep(pageCount: 6, isComplete: $isComplete, progress: $progress) { viewportHeight in
            ImmersiveSceneBlock(index: 0, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "A ideia que eu tive é bem simples.")
            }

            ImmersiveSceneBlock(index: 1, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Me dar um espaço real com Deus antes de qualquer coisa.")
            }

            ImmersiveSceneBlock(index: 2, viewportHeight: viewportHeight, minHeightFactor: 0.18) {
                ImmersiveSceneCopyText(text: "⏳ Bloquear todos os apps que poderiam me distrair...", weight: .bold)
            }

            ImmersiveSceneBlock(index: 3, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Assim, eu não caía direto no scroll... Minhas manhãs obrigatoriamente começavam com Deus.")
            }

            ImmersiveSceneBlock(
                index: 4,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.34,
                alignment: .center
            ) {
                StitchedCard(
                    pose: .centered,
                    maxWidth: immersiveCardMaxWidth,
                    contentAlignment: .center
                ) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("✨ Funciona assim ✨")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .center)

                        PremiumTopicRow(
                            emoji: "🔒",
                            title: "Apps bloqueados",
                            subtitle: "Os apps que mais tiram sua atenção continuam fechados logo cedo."
                        )

                        PremiumTopicRow(
                            emoji: "⏱️",
                            title: "Timer de oração",
                            subtitle: "Você abre o app, inicia o tempo e ora com calma."
                        )

                        PremiumTopicRow(
                            emoji: "🎵",
                            title: "Música ao acabar",
                            subtitle: "Quando o tempo termina, uma música suave avisa você."
                        )

                        PremiumTopicRow(
                            emoji: "🙏",
                            title: "Seu ritmo de oração",
                            subtitle: "Se quiser continuar, você segue orando no seu tempo."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .offset(y: 28)
            }

            ImmersiveSceneBlock(
                index: 5,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.24,
                alignment: .center,
                onFocusLock: {
                    guard !isComplete else { return }
                    isComplete = true
                    triggerOnboardingHaptic(.light)
                }
            ) {
                StitchedCard(pose: .tiltLeft, maxWidth: immersiveCardMaxWidth) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Terminou sua oração? Aí sim, tudo volta ao normal e os apps desbloqueiam.")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Text("E dessa forma tudo mudou pra mim, e eu espero que mude pra você.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.76))
                            .lineSpacing(8)
                    }
                }
            }
        }
    }
}

private struct Step3NameView: View {
    @Binding var data: OnboardingData
    @Binding var isComplete: Bool
    @Binding var progress: Double

    var body: some View {
        ImmersiveSceneStep(pageCount: 3, isComplete: $isComplete, progress: $progress) { viewportHeight in
            ImmersiveSceneBlock(index: 0, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Se isso vai fazer parte da sua rotina, faz sentido ter a sua cara.")
            }

            ImmersiveSceneBlock(index: 1, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "✍️ Coloca seu nome aqui pra personalizar sua experiência.")
            }

            ImmersiveSceneBlock(
                index: 2,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.34,
                alignment: .center,
                onFocusLock: {
                    guard !isComplete else { return }
                    isComplete = true
                    triggerOnboardingHaptic(.light)
                }
            ) {
                StitchedCard(pose: .quietRight, maxWidth: immersiveCardMaxWidth) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Como você gostaria de ser chamado?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Text("Pode ser só o primeiro nome. O importante é ficar natural pra você.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .lineSpacing(8)

                        TextField("Digite seu nome", text: $data.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.black)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.black.opacity(0.05))
                            )
                    }
                }
            }
        }
    }
}

private struct Step4AgeView: View {
    @Binding var data: OnboardingData
    @Binding var isComplete: Bool
    @Binding var progress: Double

    var body: some View {
        ImmersiveSceneStep(pageCount: 3, isComplete: $isComplete, progress: $progress) { viewportHeight in
            ImmersiveSceneBlock(index: 0, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "Cada pessoa vive a manhã de um jeito.")
            }

            ImmersiveSceneBlock(index: 1, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Saber sua idade ajuda o app a falar com você de um jeito mais certo, mais alinhado com a sua fase.")
            }

            ImmersiveSceneBlock(
                index: 2,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.42,
                alignment: .center,
                onFocusLock: {
                    guard !isComplete else { return }
                    isComplete = true
                    triggerOnboardingHaptic(.light)
                }
            ) {
                StitchedCard(
                    pose: .centered,
                    maxWidth: immersiveCardMaxWidth,
                    contentAlignment: .center
                ) {
                    VStack(spacing: 18) {
                        Text("🎂 Qual sua idade?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Text("É só pra adaptar melhor a experiência ao seu momento.")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.68))
                            .lineSpacing(8)
                            .multilineTextAlignment(.center)

                        Picker("Idade", selection: $data.ageSelection) {
                            Text("Opcional")
                                .tag(0)

                            ForEach(1...120, id: \.self) { age in
                                Text("\(age) anos")
                                    .tag(age)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 180)
                        .clipped()
                        .environment(\.colorScheme, .light)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onChange(of: data.ageSelection) {
            triggerOnboardingHaptic(.selection)
        }
    }
}

private struct Step5PhoneUsageView: View {
    @ObservedObject var screenTimeAccess: ScreenTimeAccessController
    @Binding var isComplete: Bool
    @Binding var progress: Double
    @State private var isConnectAnimating = false

    var body: some View {
        ImmersiveSceneStep(pageCount: 7, isComplete: $isComplete, progress: $progress) { viewportHeight in
            ImmersiveSceneBlock(index: 0, viewportHeight: viewportHeight, minHeightFactor: 0.20) {
                ImmersiveSceneCopyText(text: "Antes de seguir, vale encarar um dado real.")
            }

            ImmersiveSceneBlock(index: 1, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "O tempo de tela mostra quanto da sua atenção já está indo pro celular todos os dias.")
            }

            ImmersiveSceneBlock(index: 2, viewportHeight: viewportHeight, minHeightFactor: 0.18) {
                ImmersiveSceneCopyText(text: "📱 Às vezes esse número até assusta.", weight: .bold)
            }

            ImmersiveSceneBlock(index: 3, viewportHeight: viewportHeight, minHeightFactor: 0.22) {
                ImmersiveSceneCopyText(text: "Mas é justamente ele que ajuda o app a montar o bloqueio do jeito certo pra você, sem exagero e sem chute.")
            }

            ImmersiveSceneBlock(
                index: 4,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.40,
                alignment: .center
            ) {
                ZStack {
                    if screenTimeAccess.isAuthorized {
                        StitchedCard(
                            pose: .centered,
                            maxWidth: immersiveCardMaxWidth,
                            contentAlignment: .center
                        ) {
                            OfficialScreenTimeReportView()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
                        .onAppear {
                            screenTimeAccess.beginSnapshotPolling()
                        }
                    } else {
                        StitchedCard(
                            pose: .centered,
                            maxWidth: immersiveCardMaxWidth,
                            contentAlignment: .center
                        ) {
                            VStack(alignment: .center, spacing: 18) {
                                Text("📲 Conectar tempo de tela ✨")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.black)
                                    .multilineTextAlignment(.center)

                                Text("Com esse acesso, o app usa seus dados reais pra preparar o começo do dia de forma mais precisa.")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.black.opacity(0.68))
                                    .lineSpacing(8)
                                    .multilineTextAlignment(.center)

                                Button {
                                    triggerOnboardingHaptic(.medium)
                                    withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) {
                                        isConnectAnimating = true
                                    }

                                    Task {
                                        await screenTimeAccess.requestAuthorization()

                                        await MainActor.run {
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                                                isConnectAnimating = false
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        if screenTimeAccess.isRequestingAuthorization {
                                            ProgressView()
                                                .tint(.black)
                                        }

                                        Text("Conectar tempo de tela")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(Color(red: 0.90, green: 0.95, blue: 1.0))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(screenTimeAccess.isRequestingAuthorization)
                                .scaleEffect(isConnectAnimating ? 0.95 : 1)
                                .opacity(isConnectAnimating ? 0.84 : 1)

                                if let errorMessage = screenTimeAccess.lastErrorMessage {
                                    Text(errorMessage)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.red.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.94).combined(with: .opacity)))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 212, alignment: .center)
                .animation(.spring(response: 0.46, dampingFraction: 0.84), value: screenTimeAccess.isAuthorized)
            }

            ImmersiveSceneBlock(index: 5, viewportHeight: viewportHeight, minHeightFactor: 0.18) {
                ImmersiveSceneCopyText(text: "✨ Na próxima etapa, isso fica mais concreto.", weight: .bold)
            }

            ImmersiveSceneBlock(
                index: 6,
                viewportHeight: viewportHeight,
                minHeightFactor: 0.20,
                onFocusLock: {
                    guard !isComplete else { return }
                    isComplete = true
                    triggerOnboardingHaptic(.light)
                }
            ) {
                ImmersiveSceneCopyText(text: "Você vai ver o impacto da tela na sua rotina e entender, com clareza, por que vale proteger esse primeiro momento do dia só pra Deus.")
            }
        }
        .onChange(of: screenTimeAccess.isAuthorized) {
            if screenTimeAccess.isAuthorized {
                triggerOnboardingHaptic(.success)
            }
        }
    }
}

private struct Step6ImpactView: View {
    @Binding var data: OnboardingData
    let snapshot: ScreenTimeAverageSnapshot?
    let onContinue: () -> Void

    var body: some View {
        StoryImpactSequenceView(
            name: data.displayName,
            snapshot: snapshot,
            onContinue: onContinue
        )
    }
}

private struct AnalyzeProfileScreen: View {
    let onFinished: () -> Void

    @State private var progress = 0.16

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Text("Analisando seu perfil...")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))

                    Capsule()
                        .fill(Color.white)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 14)

            Text("Estamos organizando a próxima sequência com base no seu uso real.")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.82))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            triggerOnboardingHaptic(.medium)
            withAnimation(.linear(duration: 2.2)) {
                progress = 0.96
            }

            try? await Task.sleep(for: .seconds(2.4))
            triggerOnboardingHaptic(.success)
            onFinished()
        }
    }
}

private struct Step7GoalsView: View {
    @Binding var data: OnboardingData

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        OnboardingStepScroll {
            OnboardingHeadline("O que você quer alcançar com o app?")

            OnboardingBodyText("Selecione os seus cards.")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element) { index, goal in
                    SelectableOptionCard(
                        emoji: goal.emoji,
                        title: goal.title,
                        isSelected: data.selectedGoals.contains(goal),
                        tilt: index.isMultiple(of: 2) ? -1.4 : 1.2
                    ) {
                        if data.selectedGoals.contains(goal) {
                            data.selectedGoals.remove(goal)
                        } else {
                            data.selectedGoals.insert(goal)
                        }
                    }
                }
            }
        }
    }
}

private struct Step8VisionView: View {
    @Binding var data: OnboardingData

    var body: some View {
        OnboardingStepScroll {
            OnboardingHeadline("Quando você se imagina mais perto de Deus, o que você vê?")

            OnboardingBodyText("Escreva livremente. Essa visão vira combustível nos dias difíceis.")

            StitchedCard(pose: .quietRight) {
                ZStack(alignment: .topLeading) {
                    if data.trimmedVision.isEmpty {
                        Text("Exemplo: eu me vejo mais em paz, com mais direção e começando o dia com a Palavra.")
                            .font(.body)
                            .foregroundStyle(Color.black.opacity(0.38))
                            .padding(.top, 8)
                            .padding(.leading, 6)
                    }

                    TextEditor(text: $data.vision)
                        .scrollContentBackground(.hidden)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.black)
                        .frame(minHeight: 160)
                        .padding(.horizontal, 2)
                        .background(Color.clear)
                }
            }
        }
    }
}

private struct Step9WakeUpView: View {
    @Binding var data: OnboardingData

    var body: some View {
        CenteredSelectorStep(question: "⏰ Que horas você acorda?") {
            StitchedCard(pose: .centered) {
                VStack(spacing: 12) {
                    DatePicker(
                        "Horário de acordar",
                        selection: $data.wakeUpTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
                    .clipped()
                    .environment(\.colorScheme, .light)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onChange(of: data.wakeUpTime) {
            triggerOnboardingHaptic(.selection)
        }
    }
}

private struct Step10PrayerDurationView: View {
    @Binding var data: OnboardingData

    private let durationOptions = Array(1...10) + Array(stride(from: 15, through: 60, by: 5))

    var body: some View {
        CenteredSelectorStep(question: "🙏 Quanto tempo você quer orar pela manhã?") {
            StitchedCard(pose: .centered) {
                VStack(spacing: 10) {
                    Picker("Duração da oração", selection: $data.prayerDurationMinutes) {
                        ForEach(durationOptions, id: \.self) { minute in
                            Text("\(minute) min")
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
                    .clipped()
                    .environment(\.colorScheme, .light)

                    Text("Escolha um tempo possível de cumprir todos os dias.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.68))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onChange(of: data.prayerDurationMinutes) {
            triggerOnboardingHaptic(.selection)
        }
    }
}

private struct Step11BlockingAppsView: View {
    @Binding var data: OnboardingData
    @State private var isPickerPresented = false

    var body: some View {
        CenteredSelectorStep(question: "🔒 Quais apps e categorias devem ficar bloqueados até a oração?") {
            StitchedCard(pose: .centered) {
                VStack(spacing: 16) {
                    Text("Use o seletor oficial da Apple para escolher exatamente o que será bloqueado.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button(data.hasBlockingSelection ? "Editar seleção de bloqueio" : "Escolher apps para bloquear") {
                        triggerOnboardingHaptic(.medium)
                        isPickerPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.29, green: 0.57, blue: 0.92))

                    if data.hasBlockingSelection {
                        VStack(spacing: 8) {
                            Text("Seleção atual")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)

                            Text(data.blockedAppsSummary)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.black.opacity(0.72))
                                .multilineTextAlignment(.center)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $data.appSelection)
        .onChange(of: data.appSelection) {
            if data.hasBlockingSelection {
                triggerOnboardingHaptic(.success)
            }
        }
    }
}

private struct Step12ReminderView: View {
    @Binding var data: OnboardingData
    @ObservedObject var notificationAccess: NotificationAccessController
    @State private var isAuthorizing = false

    private let reminderOptions = Array(stride(from: 0, through: 60, by: 5))

    var body: some View {
        CenteredSelectorStep(question: "🔔 Quantos minutos antes você quer ser lembrado?") {
            ZStack {
                if notificationAccess.isAuthorized {
                    StitchedCard(pose: .centered) {
                        VStack(spacing: 16) {
                            Text("Seu lembrete diário já está pronto para ser configurado. ✨")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.black.opacity(0.72))
                                .multilineTextAlignment(.center)

                            Picker("Minutos antes", selection: $data.reminderLeadMinutes) {
                                ForEach(reminderOptions, id: \.self) { minute in
                                    Text("\(minute) min")
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 150)
                            .clipped()
                            .environment(\.colorScheme, .light)
                            .onChange(of: data.reminderLeadMinutes) {
                                triggerOnboardingHaptic(.selection)
                            }

                            Button(data.notificationsEnabled ? "Desligar lembrete diário" : "Usar esse lembrete diário") {
                                triggerOnboardingHaptic(.light)
                                data.notificationsEnabled.toggle()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
                } else {
                    StitchedCard(pose: .centered) {
                        VStack(spacing: 14) {
                            Text("Ative as notificações para receber um lembrete real todos os dias.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.black.opacity(0.72))
                                .multilineTextAlignment(.center)

                            Button {
                                triggerOnboardingHaptic(.medium)
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                    isAuthorizing = true
                                }

                                Task {
                                    await notificationAccess.requestAuthorization()

                                    await MainActor.run {
                                        data.notificationsEnabled = notificationAccess.isAuthorized
                                        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                            isAuthorizing = false
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if notificationAccess.isRequestingAuthorization {
                                        ProgressView()
                                            .tint(.black)
                                    }

                                    Text("Ativar notificações")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(red: 0.90, green: 0.95, blue: 1.0))
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(isAuthorizing ? 0.96 : 1)
                            .opacity(isAuthorizing ? 0.86 : 1)

                            Button("Pular por enquanto") {
                                data.notificationsEnabled = false
                            }
                            .buttonStyle(.plain)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.55))

                            if let errorMessage = notificationAccess.lastErrorMessage {
                                Text(errorMessage)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.94).combined(with: .opacity)))
                }
            }
            .frame(minHeight: 260)
            .animation(.spring(response: 0.46, dampingFraction: 0.84), value: notificationAccess.isAuthorized)
        }
        .onAppear {
            if notificationAccess.isAuthorized && !data.notificationsEnabled {
                data.notificationsEnabled = true
            }
        }
        .onChange(of: notificationAccess.isAuthorized) {
            if notificationAccess.isAuthorized {
                triggerOnboardingHaptic(.success)
            }
        }
    }
}

private struct Step13ClosingView: View {
    @Binding var data: OnboardingData

    private var orderedGoals: [OnboardingGoal] {
        OnboardingGoal.allCases.filter { data.selectedGoals.contains($0) }
    }

    var body: some View {
        OnboardingStepScroll {
            OnboardingHeadline("Vamos criar esse compromisso com Deus?")

            StitchedCard(pose: .tiltLeft) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Seu compromisso")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    Text("Horário de acordar: \(wakeTimeText)")
                        .foregroundStyle(.black)
                    Text("Duração da oração: \(data.prayerDurationMinutes) min")
                        .foregroundStyle(.black)
                    Text("Apps bloqueados: \(data.blockedAppsSummary)")
                        .foregroundStyle(.black)
                    Text("Lembrete: \(data.reminderSummary)")
                        .foregroundStyle(.black)
                }
            }

            StitchedCard(pose: .tiltRight) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seus objetivos")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    ForEach(orderedGoals, id: \.self) { goal in
                        Label("\(goal.emoji) \(goal.title)", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.black)
                    }
                }
            }

            StitchedCard(pose: .hero) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sua visão")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    Text("\"\(data.trimmedVision)\"")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.76))
                }
            }
        }
        .onAppear {
            prewarmCommitmentCelebrationAssets()
        }
    }

    private var wakeTimeText: String {
        data.wakeUpTime.formatted(date: .omitted, time: .shortened)
    }
}

private struct StoryImpactSequenceView: View {
    let name: String
    let snapshot: ScreenTimeAverageSnapshot?
    let onContinue: () -> Void

    @State private var storyIndex = 0
    @State private var activeProgress = 0.0
    @State private var isNextUnlocked = false

    private let storyDuration = 3.8
    private let storyCount = 3

    var body: some View {
        VStack(spacing: 0) {
            StoryProgressRow(
                count: storyCount,
                currentIndex: storyIndex,
                activeProgress: activeProgress
            )
            .padding(.top, 4)

            Spacer(minLength: 18)

            Group {
                switch storyIndex {
                case 0:
                    storyQuestion
                case 1:
                    storyReport
                default:
                    storyMetrics
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer(minLength: 18)

            HStack(spacing: 10) {
                Button("Anterior") {
                    triggerOnboardingHaptic(.light)
                    if storyIndex > 0 {
                        storyIndex -= 1
                    }
                }
                .buttonStyle(SecondaryOnboardingButtonStyle())
                .disabled(storyIndex == 0)
                .opacity(storyIndex == 0 ? 0.5 : 1)

                Spacer()

                Button("Próxima") {
                    triggerOnboardingHaptic(storyIndex < storyCount - 1 ? .medium : .success)
                    if storyIndex < storyCount - 1 {
                        storyIndex += 1
                    } else {
                        onContinue()
                    }
                }
                .buttonStyle(SecondaryOnboardingButtonStyle())
                .disabled(!isNextUnlocked)
                .opacity(isNextUnlocked ? 1 : 0.5)
            }
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: storyIndex) {
            triggerOnboardingHaptic(.selection)
            isNextUnlocked = false
            activeProgress = 0
            withAnimation(.linear(duration: storyDuration)) {
                activeProgress = 1
            }

            try? await Task.sleep(for: .seconds(storyDuration))
            isNextUnlocked = true
            triggerOnboardingHaptic(.light)
        }
    }

    private var storyQuestion: some View {
        VStack {
            Spacer()

            Text("Temos uma boa notícia e uma má notícia para você.")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var storyReport: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStoryHeadline("A má notícia é que a tela está ocupando um espaço que deveria ser de Deus.")

            OnboardingStoryBody(badNewsSubtitle)

            VStack(spacing: 12) {
                MetricCard(
                    value: badNewsDaysValue,
                    label: badNewsDaysLabel,
                    pose: .hero
                )

                if let snapshot {
                    MetricCard(
                        value: snapshot.averageDurationText,
                        label: "de média por dia",
                        pose: .tiltLeft
                    )
                }
            }

            Text(badNewsDisclaimer)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.72))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var storyMetrics: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStoryHeadline("A boa notícia é... Com \(AppBrand.onboardingName), sua manhã volta para Deus primeiro.")

            VStack(spacing: 12) {
                PromiseCard(
                    emoji: "🙏",
                    title: "Orar antes da distração",
                    subtitle: "Seu primeiro minuto deixa de ser da tela."
                )
                PromiseCard(
                    emoji: "📵",
                    title: "Blindar a sua manhã",
                    subtitle: "Os apps esperam até você terminar a oração."
                )
                PromiseCard(
                    emoji: "🕊️",
                    title: "Criar constância real",
                    subtitle: "Hábito construído com rotina e proteção."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var badNewsSubtitle: String {
        guard snapshot != nil else {
            return "\(name), se alguém passar 8 horas por dia no celular durante um ano, isso equivale a cerca de \(annualLossDisplay) diante da tela."
        }

        return "\(name), com sua média atual, isso equivale a cerca de \(annualLossDisplay) por ano olhando para o celular em vez de buscar a Deus primeiro."
    }

    private var badNewsDaysValue: String {
        annualLossDisplay
    }

    private var badNewsDaysLabel: String {
        if annualLossDays > 30 {
            return "equivale a isso por ano"
        }

        return snapshot == nil ? "por ano com 8h por dia" : "por ano com sua média atual"
    }

    private var badNewsDisclaimer: String {
        if snapshot == nil {
            return "Estimativa de referência: 8 horas por dia durante 365 dias equivalem a cerca de 122 dias por ano diante da tela."
        }

        return "Baseado na média oficial registrada pelo tempo de tela da Apple nos dias disponíveis."
    }

    private var annualLossDays: Int {
        snapshot?.annualDaysLost ?? referenceAnnualDaysLost
    }

    private var annualLossDisplay: String {
        if annualLossDays > 30 {
            let months = max(Int((Double(annualLossDays) / 30.0).rounded()), 1)
            return "\(months) \(months == 1 ? "mês" : "meses")"
        }

        return "\(annualLossDays) dias"
    }

    private var referenceAnnualDaysLost: Int {
        Int((((8 * 3_600) * 365) / 86_400.0).rounded())
    }
}

private struct StoryProgressRow: View {
    let count: Int
    let currentIndex: Int
    let activeProgress: Double

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.28))

                        Capsule()
                            .fill(Color.white)
                            .frame(width: proxy.size.width * progress(for: index))
                    }
                }
                .frame(height: 5)
            }
        }
    }

    private func progress(for index: Int) -> Double {
        if index < currentIndex {
            return 1
        }

        if index == currentIndex {
            return activeProgress
        }

        return 0
    }
}

private let commitmentCelebrationFistEmoji = "👊🏻"
private let commitmentCelebrationBurstEmojis = ["✨", "🙏", "📖", "🕊️", "✝️", "💛", "🙌", "☀️", "🔥"]

#if canImport(UIKit)
@MainActor
func prewarmCommitmentCelebrationAssets() {
    CommitmentCelebrationAssetCache.prewarm(
        fistEmoji: commitmentCelebrationFistEmoji,
        fistPointSize: 90,
        burstEmojis: commitmentCelebrationBurstEmojis
    )
}

private enum CommitmentCelebrationAssetCache {
    private static var uiImageCache: [String: UIImage] = [:]
    private static var cgImageCache: [String: CGImage] = [:]

    static func prewarm(
        fistEmoji: String,
        fistPointSize: CGFloat,
        burstEmojis: [String]
    ) {
        _ = uiImage(for: fistEmoji, pointSize: fistPointSize)
        burstEmojis.forEach { _ = cgImage(for: $0, pointSize: 58) }
    }

    static func uiImage(for emoji: String, pointSize: CGFloat) -> UIImage {
        let key = cacheKey(for: emoji, pointSize: pointSize)
        if let cached = uiImageCache[key] {
            return cached
        }

        let image = renderImage(for: emoji, pointSize: pointSize)
        uiImageCache[key] = image

        if let cgImage = image.cgImage {
            cgImageCache[key] = cgImage
        }

        return image
    }

    static func cgImage(for emoji: String, pointSize: CGFloat) -> CGImage? {
        let key = cacheKey(for: emoji, pointSize: pointSize)
        if let cached = cgImageCache[key] {
            return cached
        }

        let image = uiImage(for: emoji, pointSize: pointSize)
        guard let cgImage = image.cgImage else { return nil }
        cgImageCache[key] = cgImage
        return cgImage
    }

    private static func cacheKey(for emoji: String, pointSize: CGFloat) -> String {
        "\(emoji)-\(Int(pointSize.rounded()))"
    }

    private static func renderImage(for emoji: String, pointSize: CGFloat) -> UIImage {
        let font = UIFont.systemFont(ofSize: pointSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (emoji as NSString).size(withAttributes: attributes)
        let canvasSize = CGSize(
            width: max(pointSize * 1.4, textSize.width + 12),
            height: max(pointSize * 1.4, textSize.height + 12)
        )
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { _ in
            let origin = CGPoint(
                x: (canvasSize.width - textSize.width) / 2,
                y: (canvasSize.height - textSize.height) / 2
            )
            (emoji as NSString).draw(at: origin, withAttributes: attributes)
        }
    }
}
#else
func prewarmCommitmentCelebrationAssets() {}
#endif

struct CommitmentCelebrationView: View {
    let onFinished: () -> Void

    @State private var fistScale = 0.7
    @State private var fistRotation = -8.0
    @State private var fistOpacity = 1.0
    @State private var overlayOpacity = 1.0
    @State private var showContinueButton = false
    @State private var emitterTrigger = 0
    @State private var pulse = false
    @State private var hasStartedSequence = false

    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingAssetCache.backgroundImage
                .resizable()
                .scaledToFill()
                .scaleEffect(1.28)
                .offset(y: -12)
                .ignoresSafeArea()

            Rectangle()
                .fill(Color.black.opacity(0.42 * overlayOpacity))
                .ignoresSafeArea()

            ZStack {
                EmojiBurstEmitterView(
                    trigger: emitterTrigger,
                    emojis: commitmentCelebrationBurstEmojis
                )
                .allowsHitTesting(false)

                EmojiImage(emoji: commitmentCelebrationFistEmoji, pointSize: 90)
                    .frame(width: 140, height: 140)
                    .scaleEffect(fistScale * (pulse ? 1.04 : 1.0))
                    .rotationEffect(.degrees(fistRotation))
                    .opacity(fistOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showContinueButton {
                Button("Bora começar 🙌") {
                    triggerOnboardingHaptic(.success)
                    withAnimation(.easeInOut(duration: 0.35)) {
                        fistOpacity = 0
                        overlayOpacity = 0
                    }

                    Task {
                        try? await Task.sleep(for: .milliseconds(360))
                        onFinished()
                    }
                }
                .buttonStyle(PrimaryOnboardingButtonStyle())
                .padding(.horizontal, 24)
                .frame(maxWidth: 430)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            await startSequenceIfNeeded()
        }
    }

    @MainActor
    private func startSequenceIfNeeded() async {
        guard !hasStartedSequence else { return }
        hasStartedSequence = true

        prewarmCommitmentCelebrationAssets()

        // Let the first presentation frame settle before starting the spring.
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }

        triggerOnboardingHaptic(.medium)

        withAnimation(.interactiveSpring(response: 0.72, dampingFraction: 0.66)) {
            fistScale = 1.1
            fistRotation = 0
        }

        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }
        triggerOnboardingHaptic(.selection)

        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }
        triggerOnboardingHaptic(.selection)

        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }
        triggerOnboardingHaptic(.heavy)

        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        emitterTrigger += 1
        triggerOnboardingHaptic(.success)

        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulse = true
        }

        try? await Task.sleep(for: .milliseconds(2200))
        guard !Task.isCancelled else { return }
        triggerOnboardingHaptic(.light)

        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showContinueButton = true
        }
    }
}

#if canImport(UIKit)
private struct EmojiImage: View {
    let emoji: String
    let pointSize: CGFloat

    var body: some View {
        Image(uiImage: CommitmentCelebrationAssetCache.uiImage(for: emoji, pointSize: pointSize))
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
    }
}
#endif

private struct EmojiBurstEmitterView: UIViewRepresentable {
    let trigger: Int
    let emojis: [String]

    func makeUIView(context: Context) -> EmojiBurstEmitterHostView {
        EmojiBurstEmitterHostView()
    }

    func updateUIView(_ uiView: EmojiBurstEmitterHostView, context: Context) {
        guard context.coordinator.lastTrigger != trigger else { return }
        context.coordinator.lastTrigger = trigger
        guard trigger > 0 else { return }
        uiView.emitBurst(emojis: emojis)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var lastTrigger = 0
    }
}

#if canImport(UIKit)
private final class EmojiBurstEmitterHostView: UIView {
    private let emitterLayer = CAEmitterLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        emitterLayer.emitterShape = .point
        emitterLayer.birthRate = 0
        emitterLayer.renderMode = .unordered
        layer.addSublayer(emitterLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = .zero
    }

    func emitBurst(emojis: [String]) {
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterCells = emojis.compactMap(makeCell(for:))
        emitterLayer.birthRate = 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
    }

    private func makeCell(for emoji: String) -> CAEmitterCell? {
        guard let image = CommitmentCelebrationAssetCache.cgImage(for: emoji, pointSize: 58) else { return nil }

        let cell = CAEmitterCell()
        cell.contents = image
        cell.birthRate = 5
        cell.lifetime = 5.2
        cell.lifetimeRange = 0.8
        cell.velocity = 360
        cell.velocityRange = 70
        cell.yAcceleration = 210
        cell.xAcceleration = 0
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 7
        cell.spin = 1.2
        cell.spinRange = 1.8
        cell.scale = 0.24
        cell.scaleRange = 0.04
        cell.scaleSpeed = 0
        cell.alphaRange = 0
        cell.alphaSpeed = 0
        return cell
    }
}
#endif

private struct AnalyzingProfileView: View {
    @State private var progress = 0.18

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Analisando seu perfil...")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))

                        Capsule()
                            .fill(Color.white)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 14)

                Text("Estamos organizando sua próxima sequência.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.82))
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.34))
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.2)) {
                progress = 0.96
            }
        }
    }
}

private struct OnboardingStepScroll<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
        .scrollClipDisabled()
        .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity, alignment: Alignment.topLeading)
    }
}

private struct OnboardingLayoutDebugEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var onboardingLayoutDebugEnabled: Bool {
        get { self[OnboardingLayoutDebugEnabledKey.self] }
        set { self[OnboardingLayoutDebugEnabledKey.self] = newValue }
    }
}

private struct StepQuestionText: View {
    let question: String
    let centered: Bool

    init(_ question: String, centered: Bool = false) {
        self.question = question
        self.centered = centered
    }

    var body: some View {
        Text(question)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(centered ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LayoutDebugModifier: ViewModifier {
    let enabled: Bool
    let label: String
    let color: Color

    func body(content: Content) -> some View {
        if enabled {
            content.overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                        Text("\(label) \(Int(proxy.size.width))x\(Int(proxy.size.height))")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(4)
                    }
                }
            }
        } else {
            content
        }
    }
}

private extension View {
    func layoutDebug(_ enabled: Bool, label: String, color: Color) -> some View {
        modifier(LayoutDebugModifier(enabled: enabled, label: label, color: color))
    }
}

private struct OnboardingHeadline: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingBodyText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.title3.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.9))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingStoryHeadline: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingStoryBody: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.title3.weight(.medium))
            .foregroundStyle(Color.white.opacity(0.9))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct CenteredSelectorStep<Content: View>: View {
    let question: String
    @ViewBuilder private let content: Content

    init(
        question: String,
        @ViewBuilder content: () -> Content
    ) {
        self.question = question
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            StepQuestionText(question, centered: true)

            content
                .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct OnboardingBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.black.opacity(0.72))
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.black.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MetricCard: View {
    let value: String
    let label: String
    let pose: CardPose

    var body: some View {
        StitchedCard(pose: pose) {
            HStack {
                Text(value)
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.black)
                Spacer()
                Text(label)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(Color.black.opacity(0.72))
            }
        }
    }
}

private struct PromiseCard: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        StitchedCard(pose: .centered) {
            HStack(alignment: .top, spacing: 12) {
                Text(emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.72))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        }
    }
}

private struct PremiumTopicRow: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(Color(red: 0.91, green: 0.95, blue: 1.0))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.black)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.04))
        )
    }
}

private struct PullDownHintBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up")
                .font(.caption.weight(.bold))

            Text("Puxe para cima")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)
    }
}

private struct SelectableOptionCard: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let tilt: Double
    let action: () -> Void

    private var fillColor: Color {
        isSelected ? Color(red: 0.86, green: 0.92, blue: 1.0) : Color.white.opacity(0.95)
    }

    private var strokeColor: Color {
        isSelected ? Color(red: 0.29, green: 0.57, blue: 0.92) : Color.black.opacity(0.08)
    }

    private var effectiveRotation: Double {
        0
    }

    private var shadowOpacity: Double {
        isSelected ? 0.24 : 0.08
    }

    var body: some View {
        Button {
            triggerOnboardingHaptic(.light)
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(emoji)
                        .font(.title3)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.16, green: 0.45, blue: 0.86))
                    }
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(strokeColor, lineWidth: isSelected ? 1.6 : 1.2)
            )
            .shadow(color: Color.black.opacity(shadowOpacity), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 8 : 4)
        }
        .buttonStyle(.plain)
    }
}

private struct SelectableTag: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    private var fillColor: Color {
        selected ? Color(red: 0.86, green: 0.92, blue: 1.0) : Color.white.opacity(0.95)
    }

    private var strokeColor: Color {
        selected ? Color(red: 0.29, green: 0.57, blue: 0.92) : Color.black.opacity(0.08)
    }

    private var shadowOpacity: Double {
        selected ? 0.16 : 0.08
    }

    var body: some View {
        Button {
            triggerOnboardingHaptic(.light)
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(shadowOpacity), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct FlowWrapLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: spacing)], spacing: spacing) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView(
            didCompleteOnboarding: .constant(false),
            savedName: .constant("")
        )
    }
}
