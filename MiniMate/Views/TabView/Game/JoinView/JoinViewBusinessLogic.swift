// JoinViewBusinessLogic.swift
// MiniMate

import Foundation

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business, validation, and presentation logic for joining a game.
class JoinViewBusinessLogic {
    
    // MARK: - Input Formatting & Validation
    
    /// Cleans and formats a scanned QR code string
    func formatScannedCode(_ code: String) -> String {
        return code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    
    /// Filters a manually typed game code to ensure it's valid (6 alphanumeric characters max)
    func formatEnteredCode(_ code: String) -> String {
        let filtered = code.uppercased().filter { $0.isLetter || $0.isNumber }
        return String(filtered.prefix(6))
    }
    
    // MARK: - Presentation Logic
    
    /// Determines if the Join Game button should be disabled based on code validation
    func isJoinButtonDisabled(gameCode: String) -> Bool {
        return gameCode.count != 6
    }
    
    /// Returns the appropriate opacity for the Join Game button
    func getJoinButtonOpacity(gameCode: String) -> Double {
        return isJoinButtonDisabled(gameCode: gameCode) ? 0.5 : 1.0
    }
    
    /// Provides a fallback string for a missing location name
    func getLocationName(from name: String?) -> String {
        return name ?? "No Location"
    }
    
    /// Formats the players section header
    func getPlayersHeaderText(playerCount: Int) -> String {
        return "Players: \(playerCount)"
    }
    
    // MARK: - ViewModel State Logic
    
    /// Validates if a join attempt should proceed based on the game code
    func canAttemptJoin(gameCode: String) -> Bool {
        return !gameCode.isEmpty
    }
    
    /// Determines if a joined player should be removed when the view's host state changes
    func shouldLeaveGameOnHostDismiss(showHost: Bool, gameId: String, hasStarted: Bool) -> Bool {
        return !showHost && !gameId.isEmpty && !hasStarted
    }
    
    /// Validates if navigation should occur based on the game's started status
    func shouldNavigateOnGameStart(hasStarted: Bool) -> Bool {
        return hasStarted
    }
    
    /// Validates if the local state should be reset because the game was dismissed
    func shouldResetOnGameDismiss(isDismissed: Bool) -> Bool {
        return isDismissed
    }
}
