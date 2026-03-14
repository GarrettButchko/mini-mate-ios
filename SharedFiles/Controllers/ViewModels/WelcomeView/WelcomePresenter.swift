//
//  WelcomePresenter.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation

class WelcomePresenter {
    // MARK: - Callbacks for the ViewModel
    var onTextUpdate: ((String) -> Void)?
    var onShouldShowLoading: ((Bool) -> Void)?
    var onReadyToNavigate: (() -> Void)?

    // MARK: - Private
    private let fullText: String
    private let typingSpeed = 0.05
    private var animationTriggered = false

    // MARK: - Init
    init(welcomeText: String) {
        self.fullText = welcomeText
    }

    // MARK: - Public API
    func start() {
        startTypingAnimation()
    }

    // MARK: - Typing Animation
    private func startTypingAnimation() {
        var currentText = ""
        animationTriggered = false

        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed * Double(index)) {
                currentText.append(character)
                self.onTextUpdate?(currentText)

                if currentText == self.fullText, !self.animationTriggered {
                    self.animationTriggered = true
                    self.handleAnimationCompletion()
                }
            }
        }
    }

    // MARK: - Post Animation Logic
    private func handleAnimationCompletion() {
        if NetworkChecker.shared.isConnected {
            onReadyToNavigate?()
        } else {
            onShouldShowLoading?(true)
            pollUntilInternet()
        }
    }

    // MARK: - Network Polling
    private func pollUntilInternet() {
        if NetworkChecker.shared.isConnected {
            onShouldShowLoading?(false)
            onReadyToNavigate?()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.pollUntilInternet()
            }
        }
    }
}
