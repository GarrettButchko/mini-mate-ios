//
//  WelcomeViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI
import Combine

@MainActor
final class WelcomeViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var displayedText = ""
    @Published var showLoading = false

    // MARK: - Private
    private let viewManager: ViewManager
    private let fullText: String
    private let typingSpeed = 0.05
    private var animationTriggered = false

    // MARK: - Init
    init(viewManager: ViewManager, welcomeText: String) {
        self.viewManager = viewManager
        self.fullText = welcomeText
    }

    // MARK: - Lifecycle
    func onAppear() {
        startTypingAnimation()
    }

    // MARK: - Typing Animation
    private func startTypingAnimation() {
        var currentText = ""
        animationTriggered = false

        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed * Double(index)) { [weak self] in
                guard let self = self else { return }
                
                currentText.append(character)
                self.displayedText = currentText

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
            navigateToSignIn()
        } else {
            showLoading = true
            pollUntilInternet()
        }
    }

    // MARK: - Network Polling
    private func pollUntilInternet() {
        if NetworkChecker.shared.isConnected {
            showLoading = false
            navigateToSignIn()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.pollUntilInternet()
            }
        }
    }

    // MARK: - Navigation
    private func navigateToSignIn() {
        withAnimation {
            viewManager.navigateToSignIn()
        }
    }
}
