// HostViewBusinessLogic.swift
// MiniMate

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business and presentation logic, stripped of any UI or platform-specific imports.
class HostViewBusinessLogic {
    
    // MARK: - Presentation Logic
    
    func getHeaderTitle(isOnline: Bool) -> String {
        return isOnline ? "Hosting Game" : "Game Setup"
    }
    
    func getPlayersHeaderText(playerCount: Int) -> String {
        return "Players: \(playerCount)"
    }
    
    // MARK: - Business Logic
    
    /// Determines if the game should be dismissed when the view disappears
    func shouldDismissGameOnDisappear(isStarted: Bool, isDismissed: Bool, showHost: Bool) -> Bool {
        return !isStarted && !isDismissed && !showHost
    }
    
    /// Orchestrates the actions required when a guest clicks the back button
    func handleGuestBackAction(dismissGame: () -> Void, navigateToSignIn: () -> Void) {
        navigateToSignIn()
        dismissGame()
    }
    
    /// Orchestrates the process of starting a game, conditionally handling guest storage
    func handleStartGame(isGuest: Bool, deleteGuestGame: () -> Void, performStart: () -> Void) {
        performStart()
        if isGuest {
            deleteGuestGame()
        }
    }
    
    /// Evaluates user deletion and delegates the removal if valid
    func handleDeletePlayer(playerId: String?, removePlayer: (String) -> Void) {
        if let id = playerId {
            removePlayer(id)
        }
    }
}
