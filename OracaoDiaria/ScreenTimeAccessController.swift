//
//  ScreenTimeAccessController.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import Foundation
import Combine
import FamilyControls

@MainActor
final class ScreenTimeAccessController: ObservableObject {
    @Published private(set) var authorizationStatus: AuthorizationStatus
    @Published private(set) var isRequestingAuthorization = false
    @Published private(set) var latestSnapshot: ScreenTimeAverageSnapshot?
    @Published var lastErrorMessage: String?

    private var snapshotPollingTask: Task<Void, Never>?

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        latestSnapshot = ScreenTimeSnapshotStore.load()
    }

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    func refresh() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        latestSnapshot = ScreenTimeSnapshotStore.load()
    }

    func requestAuthorization() async {
        guard !isRequestingAuthorization else { return }

        isRequestingAuthorization = true
        lastErrorMessage = nil

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refresh()
        } catch {
            lastErrorMessage = error.localizedDescription
            refresh()
        }

        isRequestingAuthorization = false
    }

    func refreshSnapshot() {
        latestSnapshot = ScreenTimeSnapshotStore.load()
    }

    func beginSnapshotPolling() {
        snapshotPollingTask?.cancel()
        snapshotPollingTask = Task { @MainActor in
            for _ in 0..<6 {
                refreshSnapshot()
                try? await Task.sleep(for: .seconds(0.75))
            }
        }
    }
}
