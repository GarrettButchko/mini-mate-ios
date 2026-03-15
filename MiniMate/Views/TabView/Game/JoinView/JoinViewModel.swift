//
//  JoinViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/17/25.
//

import SwiftUI
import Combine

@MainActor
final class JoinViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var gameCode: String = ""
    @Published var inGame: Bool = false
    @Published var showExitAlert: Bool = false
    @Published var message: String = ""

    // MARK: - Dependencies
    let gameModel: GameViewModel
    let authModel: AuthViewModel
    
    // Platform-agnostic business logic isolated for KMP
    private let logic = JoinViewBusinessLogic()

    // MARK: - Init
    init(
        gameModel: GameViewModel,
        authModel: AuthViewModel
    ) {
        self.gameModel = gameModel
        self.authModel = authModel
    }

    // MARK: - Actions

    func joinGame() {
        guard logic.canAttemptJoin(gameCode: gameCode) else { return }

        gameModel.joinGame(id: gameCode, userId: authModel.userModel!.googleId) { [weak self] success, error in
            guard let self else { return }

            if success {
                withAnimation {
                    self.inGame = true
                }
            } else {
                if let error {
                    withAnimation{
                        self.message = error
                    }
                }
            }
        }
    }

    func leaveGame() {
        guard let userID = authModel.userModel?.googleId else { return }

        gameModel.leaveGame(userId: userID)
        gameCode = ""
        withAnimation {
            inGame = false
        }
    }

    // MARK: - External State Reactions

    func hostDidDismiss(showHost: Bool) {
        let shouldLeave = logic.shouldLeaveGameOnHostDismiss(
            showHost: showHost,
            gameId: gameModel.gameValue.id,
            hasStarted: gameModel.gameValue.started
        )
        
        guard shouldLeave else { return }

        gameModel.leaveGame(userId: gameModel.gameValue.id)
        withAnimation {
            inGame = false
        }
    }

    func gameDidStart(_ started: Bool, onNavigate: () -> Void) {
        if logic.shouldNavigateOnGameStart(hasStarted: started) {
            onNavigate()
        }
    }

    func gameDidDismiss(_ dismissed: Bool) {
        if logic.shouldResetOnGameDismiss(isDismissed: dismissed) {
            gameCode = ""
            withAnimation {
                inGame = false
            }
        }
    }
}
