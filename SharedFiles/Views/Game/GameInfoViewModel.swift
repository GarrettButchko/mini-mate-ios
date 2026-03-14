import Foundation
import Combine

/// This ViewModel takes a `Game` model and prepares its properties for display in the UI.
/// It contains all the presentation logic, such as formatting dates, converting numbers to strings,
/// and providing default values for optional properties.
/// In a Kotlin Multiplatform architecture, the logic in this class would reside in the shared module.
@MainActor
final class GameInfoViewModel: ObservableObject {
    
    // MARK: - Formatted Properties for UI
    let gameId: String
    let playerCount: String
    let holeCount: String
    let dateStarted: String
    let location: String
    let courseId: String

    // MARK: - Initializer

    init(game: Game) {
        // Perform all data-to-string conversions and formatting here.
        self.gameId = game.id
        self.playerCount = "\(game.players.count)"
        self.holeCount = "\(game.numberOfHoles)"
        self.dateStarted = game.date.formatted(date: .abbreviated, time: .omitted)
        self.location = game.locationName ?? "No Location"
        self.courseId = game.courseID ?? "No Course ID"
    }
}
