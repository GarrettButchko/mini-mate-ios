// ScoreCardBusinessLogic.swift
// MiniMate

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business, logic, and formatting rules for the scorecard view.
class ScoreCardBusinessLogic {
    
    // MARK: - Game Calculations
    
    /// Determines the correct number of holes to display on the scorecard
    func getHoleCount(hasCustomPar: Bool?, courseNumHoles: Int?, gameNumHoles: Int) -> Int {
        if let customPar = hasCustomPar, !customPar, let courseHoles = courseNumHoles {
            return courseHoles
        } else {
            return gameNumHoles
        }
    }
    
    /// Calculates the total par for a course based on its individual hole pars
    func calculateTotalPar(pars: [Int?]) -> Int {
        return pars.compactMap { $0 }.reduce(0, +)
    }
    
    // MARK: - UI Presentation Rules
    
    /// Determines if ad banners should be displayed to the current user
    func shouldShowAds(isConnected: Bool, isGuest: Bool, isPro: Bool?) -> Bool {
        let isUserPro = isPro ?? false
        return isConnected && (isGuest || !isUserPro)
    }
    
    /// Provides the correct back button label based on the user's login state
    func getBackButtonText(isGuest: Bool) -> String {
        return isGuest ? "Back to Sign In Menu" : "Go Back to Main Menu"
    }
    
    /// Provides the correct back button system icon name based on the user's login state
    func getBackButtonIcon(isGuest: Bool) -> String {
        return isGuest ? "person.crop.circle" : "house.fill"
    }
    
    /// Formats a raw seconds integer into a MM:SS string
    func formatTimeString(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    // MARK: - Action Handlers
    
    /// Safely processes the end game action, ensuring it is only uploaded/persisted once
    func processEndGame(hasUploaded: Bool, persistAction: () -> Void, markAsUploaded: () -> Void) {
        guard !hasUploaded else { return }
        persistAction()
        markAsUploaded()
    }
}
