//
//  OnboardingIntroMediaView.swift
//  OracaoDiaria
//
//  Created by Codex on 15/03/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct OnboardingIntroMediaView: View {
    static let videoNames = [
        ("welcome-video", "mp4"),
        ("intro-video", "mp4"),
        ("onboarding_intro", "mp4"),
    ]
    private static let resolvedBundledVideoURL: URL? = {
        for (name, ext) in videoNames {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }()

    static var hasBundledVideo: Bool {
        resolvedBundledVideoURL != nil
    }

    var body: some View {
        if let url = Self.resolvedBundledVideoURL {
            LoopingVideoSurface(url: url)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 16)
        }
    }
}

private struct LoopingVideoSurface: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerView {
        let view = LoopingPlayerView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) {
        uiView.configure(url: url)
    }
}

private final class LoopingPlayerView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var configuredURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func configure(url: URL) {
        guard configuredURL != url else {
            player?.play()
            return
        }

        configuredURL = url
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        let looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = true
        player.play()

        self.player = player
        self.looper = looper
        playerLayer.player = player
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            player?.pause()
        } else {
            player?.play()
        }
    }
}
