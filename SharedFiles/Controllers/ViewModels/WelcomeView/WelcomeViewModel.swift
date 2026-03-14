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
    private let presenter: WelcomePresenter

    // MARK: - Init
    init(viewManager: ViewManager, welcomeText: String) {
        self.viewManager = viewManager
        self.presenter = WelcomePresenter(welcomeText: welcomeText)
        setupBindings()
    }

    // MARK: - Lifecycle
    func onAppear() {
        presenter.start()
    }

    // MARK: - Bindings
    private func setupBindings() {
        presenter.onTextUpdate = { [weak self] newText in
            self?.displayedText = newText
        }
        presenter.onShouldShowLoading = { [weak self] shouldShow in
            self?.showLoading = shouldShow
        }
        presenter.onReadyToNavigate = { [weak self] in
            self?.navigateToSignIn()
        }
    }

    // MARK: - Navigation
    private func navigateToSignIn() {
        withAnimation {
            viewManager.navigateToSignIn()
        }
    }
}
