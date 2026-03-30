// RecapViewBusinessLogic.swift
// MiniMate

enum PlayerStanding: Equatable {
    case first
    case second
    case third
}

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business and presentation logic for the recap screen.
class RecapViewBusinessLogic {
    
    // MARK: - Business Logic
    
    /// Sorts players by their total strokes in ascending order
    func sortPlayers(from game: Game?) -> [Player] {
        guard let game = game else { return [] }
        return game.players.sorted { $0.totalStrokes < $1.totalStrokes }
    }
    
    // MARK: - Presentation Logic
    
    /// Returns the medal emoji associated with a standing
    func getMoji(for place: PlayerStanding?) -> String {
        switch place {
        case .first: return "🥇"
        case .second: return "🥈"
        case .third: return "🥉"
        default: return ""
        }
    }
    
    /// Returns the platform-agnostic image size based on standing
    func getImageSize(for place: PlayerStanding?) -> Double {
        switch place {
        case .first: return 70.0
        case .second, .third: return 40.0
        default: return 30.0
        }
    }
    
    /// Formats the player's name based on their placement and whether they are the only player
    func formatPlayerName(name: String, place: PlayerStanding?, onlyPlayer: Bool) -> String {
        if place != nil && !onlyPlayer {
            return name + getMoji(for: place)
        }
        return name
    }
}
