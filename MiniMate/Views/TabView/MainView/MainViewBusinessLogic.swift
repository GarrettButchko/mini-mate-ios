// MainViewBusinessLogic.swift
// MiniMate

import Foundation

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business, calculation, and formatting rules for the main view.
class MainViewBusinessLogic {
    
    // MARK: - Access Rules
    
    /// Determines if the user is restricted from playing based on their pro status and game count.
    func isPlayDisabled(isPro: Bool?, gameCount: Int) -> Bool {
        let proStatus = isPro ?? false
        return !proStatus && gameCount >= 2
    }
    
    /// Determines if the Pro upgrade stopper message should be shown.
    func shouldShowProStopper(isPro: Bool?, gameCount: Int) -> Bool {
        return isPlayDisabled(isPro: isPro, gameCount: gameCount)
    }
    
    // MARK: - Data Filtering
    
    /// Filters all available games to only those matching the user's game IDs.
    func filterUserGames(allGames: [Game], userGameIDs: [String]) -> [Game] {
        let ids = Set(userGameIDs)
        return allGames.filter { ids.contains($0.id) }
    }
    
    // MARK: - Presentation Formatting
    
    /// Provides a fallback string for the user's greeting name.
    func getGreetingName(name: String?) -> String {
        return name ?? "User"
    }
    
    /// Provides the correct header title based on the online mode state.
    func getHeaderTitle(isOnlineMode: Bool) -> String {
        return isOnlineMode ? "Online Options" : "Start a Round"
    }
    
    /// Provides the correct informational message based on the online mode state.
    func getInfoMessage(isOnlineMode: Bool) -> String {
        if isOnlineMode {
            return "Host starts a server game. Join connects to an existing one. Multiple devices sync in real time."
        } else {
            return "Quick starts a local game. Online lets you host or join a networked game."
        }
    }
    
    /// Formats the winner's name to include a medal emoji.
    func formatWinnerName(name: String?) -> String {
        let baseName = name ?? "N/A"
        return "\(baseName) 🥇"
    }
    
    // MARK: - Configuration Rules
    
    /// The duration in seconds that the Pro promotion text should be displayed before hiding.
    var proPromotionDisplayDuration: TimeInterval {
        return 7.0
    }
}
