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
    @State private var showsCelebrationDebug = false

    var body: some View {
        Group {
            if didCompleteOnboarding {
                HomePlaceholderView(userName: savedUserName)
            } else {
                OnboardingFlowView(
                    didCompleteOnboarding: $didCompleteOnboarding,
                    savedName: $savedUserName
                )
            }
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            Button("Testar animação") {
                showsCelebrationDebug = true
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.66))
            )
            .padding(.trailing, 16)
            .padding(.bottom, 18)
        }
        .fullScreenCover(isPresented: $showsCelebrationDebug) {
            CommitmentCelebrationView {
                showsCelebrationDebug = false
            }
        }
        #endif
    }
}

private struct HomePlaceholderView: View {
    let userName: String

    private var greetingName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "amiga" : trimmed
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(alignment: .leading, spacing: 16) {
                Text("Bom te ver, \(greetingName).")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)

                Text("Tudo pronto. Amanhã seus apps estarão bloqueados até você orar.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text("A tela principal do app entra no próximo passo.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
