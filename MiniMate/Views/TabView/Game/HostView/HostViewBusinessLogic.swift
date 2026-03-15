// HostViewBusinessLogic.swift
// MiniMate
import Foundation
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
    
    // MARK: - View Logic
    
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
    
    // MARK: - ViewModel Timer & Formatting Logic
    
    /// Calculates the remaining time based on the last updated date and time-to-live (TTL)
    func calculateTimeRemaining(lastUpdated: Date, ttl: TimeInterval) -> TimeInterval {
        let expire = lastUpdated.addingTimeInterval(ttl)
        return max(0, expire.timeIntervalSinceNow)
    }
    
    /// Validates if enough time has passed to allow a timer reset (spam prevention)
    func canResetTimer(lastResetTime: Date?, cooldown: TimeInterval, currentTime: Date = Date()) -> Bool {
        guard let lastReset = lastResetTime else { return true }
        return currentTime.timeIntervalSince(lastReset) >= cooldown
    }
    
    /// Formats an integer representing seconds into a "MM:SS" string
    func formatTimeString(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    /// Determines the number of holes to set for a course, defaulting to 18 if pars aren't provided
    func determineDefaultHoles(parsCount: Int?) -> Int {
        return parsCount ?? 18
    }
}
