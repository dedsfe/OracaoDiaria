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
    @Binding var didCompleteOnboarding: Bool
    @Binding var savedName: String

    @StateObject private var viewModel: OnboardingViewModel

    @MainActor
    init(
        didCompleteOnboarding: Binding<Bool>,
        savedName: Binding<String>
    ) {
        self._didCompleteOnboarding = didCompleteOnboarding
        self._savedName = savedName
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
        ZStack {
            if viewModel.isIntroStep {
                Color.black
                    .ignoresSafeArea()
            } else {
                OnboardingBackground()
            }

            VStack(alignment: .leading, spacing: 16) {
                if viewModel.showsProgressHeader {
                    progressHeader
                }

                ZStack {
                    currentStepView
                        .id(viewModel.stepIndex)
                        .transition(stepTransition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if viewModel.showsGlobalNavigation {
                    navigationButtons
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, viewModel.isIntroStep ? 20 : 24)
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
            Step2ProblemView()
        case 2:
            Step3PromiseView()
        case 3:
            Step3NameView(data: $viewModel.data)
        case 4:
            Step4AgeView(data: $viewModel.data)
        case 5:
            Step5PhoneUsageView(screenTimeAccess: viewModel.screenTimeAccess)
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
                Text("Etapa \(viewModel.progressStepNumber) de \(viewModel.progressStageCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()

                Text("\(Int((viewModel.progressValue * 100).rounded()))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.68))
                    Capsule()
                        .fill(Color.white)
                        .frame(width: proxy.size.width * viewModel.progressValue)
                }
            }
            .frame(height: 14)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.84), value: viewModel.stepIndex)
    }

    private var stepTransition: AnyTransition {
        switch viewModel.navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
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

            Button {
                dismissKeyboard()
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
            .disabled(!viewModel.canProceed)
            .opacity(viewModel.canProceed ? 1 : 0.45)
        }
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

private struct Step2ProblemView: View {
    var body: some View {
        OnboardingStepScroll {
            Text("Quando você acorda, já vai direto pras redes sociais e nunca lembra orar?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Você não está sozinho. As distrações chegam cedo demais e acabam ocupando o lugar da oração.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

            StitchedCard(pose: .hero) {
                Label("E se toda vez que você pegasse o celular, você só pudesse mexer depois de falar com Deus?", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
            }
        }
    }
}

private struct Step3PromiseView: View {
    var body: some View {
        OnboardingStepScroll {
            Text("Seus apps ficam bloqueados até você orar.")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Simples assim. Você define o tempo, a gente protege o momento.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

            StitchedCard(pose: .tiltRight) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Como funciona")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

                    OnboardingBullet(icon: "1.circle.fill", text: "Você acorda e todos os apps estão bloqueados.")
                    OnboardingBullet(icon: "2.circle.fill", text: "Você clica em \"Começar Oração\" e define quanto tempo vai orar.")
                    OnboardingBullet(icon: "3.circle.fill", text: "Quando terminar, toca uma música e tudo é liberado.")
                }
            }

            StitchedCard(pose: .tiltLeft) {
                Text("Sem distrações. Sem notificações. Só você e Deus primeiro.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.black)
            }
        }
    }
}

private struct Step3NameView: View {
    @Binding var data: OnboardingData

    var body: some View {
        OnboardingStepScroll {
            Text("Primeiro: com quem estamos orando?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Seu nome vai aparecer nos momentos mais importantes da jornada.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

            StitchedCard(pose: .quietRight) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nome")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)

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

private struct Step4AgeView: View {
    @Binding var data: OnboardingData

    var body: some View {
        CenteredSelectorStep(question: "🎂 Qual sua idade?") {
            StitchedCard(pose: .centered) {
                VStack(spacing: 12) {
                    Text("Essa resposta é opcional. Serve para adaptar a linguagem e o ritmo da jornada.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.black.opacity(0.68))
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
        .onChange(of: data.ageSelection) {
            triggerOnboardingHaptic(.selection)
        }
    }
}

private struct Step5PhoneUsageView: View {
    @ObservedObject var screenTimeAccess: ScreenTimeAccessController
    @State private var isConnectAnimating = false

    var body: some View {
        OnboardingStepScroll {
            Text("Agora vamos puxar seu tempo real oficial do iPhone.")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Sem estimativa manual. A gente usa o Screen Time da Apple para mostrar sua média diária real.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

            ZStack {
                if screenTimeAccess.isAuthorized {
                    StitchedCard(pose: .hero) {
                        OfficialScreenTimeReportView()
                    }
                    .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .opacity))
                    .onAppear {
                        screenTimeAccess.beginSnapshotPolling()
                    }
                } else {
                    StitchedCard(pose: .centered) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conectar Screen Time do iPhone")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)

                            Text("Toque para liberar o Screen Time. Sem isso, a próxima etapa e o bloqueio real de apps não podem ser configurados.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.black.opacity(0.68))

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

                                    Text("Conectar Screen Time")
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
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.94).combined(with: .opacity)))
                }
            }
            .frame(minHeight: 212)
            .animation(.spring(response: 0.46, dampingFraction: 0.84), value: screenTimeAccess.isAuthorized)
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
            Text("O que você quer alcançar com o app?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Escolha uma ou mais respostas. Isso vai personalizar sua experiência.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

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
            Text("Quando você se imagina mais perto de Deus, o que você vê?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Escreva livremente. Essa visão vira combustível nos dias difíceis.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.9))

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
            Text("Vamos criar esse compromisso com Deus?")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var storyReport: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A má notícia é que a tela está ocupando um espaço que deveria ser de Deus.")
                .font(.system(size: 31, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(badNewsSubtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.90))

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
            Text("Com \(AppBrand.onboardingName), sua manhã volta para Deus primeiro.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

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
        guard let snapshot else {
            return "\(name), se alguém passar 8 horas por dia no celular durante um ano, isso vira mais de quatro meses inteiros diante da tela."
        }

        return "\(name), com sua média atual, isso representa cerca de \(snapshot.annualDaysLost) dias por ano olhando para o celular em vez de buscar a Deus primeiro."
    }

    private var badNewsDaysValue: String {
        guard let snapshot else {
            return "\(referenceAnnualDaysLost) dias"
        }

        return "\(snapshot.annualDaysLost) dias"
    }

    private var badNewsDaysLabel: String {
        snapshot == nil ? "por ano com 8h por dia" : "por ano com sua média atual"
    }

    private var badNewsDisclaimer: String {
        if snapshot == nil {
            return "Estimativa de referência: 8 horas por dia durante 365 dias equivalem a cerca de 122 dias por ano diante da tela."
        }

        return "Baseado na média oficial registrada pelo Screen Time da Apple nos dias disponíveis."
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

struct CommitmentCelebrationView: View {
    let onFinished: () -> Void

    @State private var fistScale = 0.78
    @State private var fistRotation = -8.0
    @State private var fistOpacity = 1.0
    @State private var overlayOpacity = 1.0
    @State private var showContinueButton = false
    @State private var emitterTrigger = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(overlayOpacity)
                .ignoresSafeArea()

            ZStack {
                EmojiBurstEmitterView(
                    trigger: emitterTrigger,
                    emojis: ["✨", "🙏", "📖", "🕊️", "✝️", "💛", "🙌", "☀️", "🔥"]
                )
                .allowsHitTesting(false)

                Text("👊🏻")
                    .font(.system(size: 72))
                    .scaleEffect(fistScale)
                    .rotationEffect(.degrees(fistRotation))
                    .opacity(fistOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showContinueButton {
                Button("Seguir") {
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
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            triggerOnboardingHaptic(.medium)

            withAnimation(.interactiveSpring(response: 0.72, dampingFraction: 0.66)) {
                fistScale = 2.25
                fistRotation = 0
            }

            try? await Task.sleep(for: .milliseconds(180))
            triggerOnboardingHaptic(.selection)
            try? await Task.sleep(for: .milliseconds(180))
            triggerOnboardingHaptic(.selection)
            try? await Task.sleep(for: .milliseconds(180))
            triggerOnboardingHaptic(.heavy)

            emitterTrigger += 1
            triggerOnboardingHaptic(.success)

            try? await Task.sleep(for: .milliseconds(2200))
            triggerOnboardingHaptic(.light)

            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                showContinueButton = true
            }
        }
    }
}

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
    private static var emojiImageCache: [String: CGImage] = [:]

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
        guard let image = emojiCGImage(for: emoji) else { return nil }

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

    private func emojiCGImage(for emoji: String) -> CGImage? {
        if let cached = Self.emojiImageCache[emoji] {
            return cached
        }

        let font = UIFont.systemFont(ofSize: 58)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (emoji as NSString).size(withAttributes: attributes)
        let canvasSize = CGSize(width: max(72, textSize.width + 12), height: max(72, textSize.height + 12))
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        let image = renderer.image { _ in
            let origin = CGPoint(
                x: (canvasSize.width - textSize.width) / 2,
                y: (canvasSize.height - textSize.height) / 2
            )
            (emoji as NSString).draw(at: origin, withAttributes: attributes)
        }

        guard let cgImage = image.cgImage else { return nil }
        Self.emojiImageCache[emoji] = cgImage
        return cgImage
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
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                .frame(maxWidth: 420)

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
            .scaleEffect(isSelected ? 1.02 : 1)
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
