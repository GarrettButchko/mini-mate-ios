// GameBusinessLogic.swift
// MiniMate

import Foundation

enum JoinGameStatus {
    case success
    case error(String)
}

/// A platform-agnostic class designed to be easily migrated to a Kotlin Multiplatform shared module.
/// It contains pure business, validation, and data manipulation logic for the core game state.
class GameBusinessLogic {
    
    // MARK: - Generation & Setup
    
    /// Generates a random alphanumeric game code of a specified length
    func generateGameCode(length: Int = 6) -> String {
        let chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    
    /// Prepares a new game state for creation
    func setupNewGame(game: Game, hostId: String, course: Course?, newId: String) {
        game.live = true
        game.id = newId
        game.hostUserId = hostId
        
        if let course = course {
            game.courseID = course.id
            game.locationName = course.name
        }
    }
    
    // MARK: - Player & Hole Management
    
    /// Initializes holes for a player if they don't already match the game's total holes
    func initializeHoles(for player: Player, totalHoles: Int) {
        guard player.holes.count != totalHoles else { return }
        player.holes = []
        player.holes = (0..<totalHoles).map {
            let hole = Hole(number: $0 + 1)
            hole.player = player
            return hole
        }
    }
    
    /// Attaches existing holes and generates missing holes to match the total required
    func attachHoles(to player: Player, totalHoles: Int) {
        // Preserve existing strokes and ensure player linkage.
        for hole in player.holes {
            hole.player = player
        }

        if player.holes.count < totalHoles {
            let existing = Set(player.holes.map(\.number))
            for n in 1...totalHoles where !existing.contains(n) {
                let hole = Hole(number: n)
                hole.player = player
                player.holes.append(hole)
            }
        }

        player.holes.sort { $0.number < $1.number }
    }
    
    /// Merges remote player data into the local player model
    func mergePlayer(local: Player, remote: Player) {
        local.inGame = remote.inGame
        local.name = remote.name
        local.photoURL = remote.photoURL
        local.email = remote.email

        for remoteHole in remote.holes {
            if let localHole = local.holes.first(where: { $0.number == remoteHole.number }) {
                localHole.strokes = remoteHole.strokes
            } else {
                let hole = Hole(number: remoteHole.number, strokes: remoteHole.strokes)
                hole.player = local
                local.holes.append(hole)
            }
        }
        local.holes.sort { $0.number < $1.number }
    }
    
    /// Checks if a player exists in the game by their user ID
    func isPlayerInGame(players: [Player], userId: String) -> Bool {
        return players.contains(where: { $0.userId == userId })
    }
    
    // MARK: - Validation
    
    /// Validates whether a user is allowed to join the requested game
    func validateJoinGame(game: Game?, userId: String) -> JoinGameStatus {
        guard let game = game else {
            return .error("Game not found. Please check the code and try again.")
        }
        
        if game.dismissed {
            return .error("This game has been dismissed by the host.")
        } else if game.started {
            return .error("This game has already started.")
        } else if game.completed {
            return .error("This game has already been completed.")
        } else if isPlayerInGame(players: game.players, userId: userId) {
            return .error("You are already in this game. Use a different account to join")
        } else {
            return .success
        }
    }
    
    // MARK: - Deep Copy
    
    /// Creates a deep copy of a Game object for persistence
    func createDeepCopy(of source: Game) -> Game {
        return Game(
            id: source.id,
            hostUserId: source.hostUserId,
            date: source.date,
            completed: source.completed,
            numberOfHoles: source.numberOfHoles,
            started: source.started,
            dismissed: source.dismissed,
            live: source.live,
            lastUpdated: source.lastUpdated,
            courseID: source.courseID,
            players: source.players.map { player in
                Player(
                    id: player.id,
                    userId: player.userId,
                    name: player.name,
                    photoURL: player.photoURL,
                    holes: player.holes.map { Hole(number: $0.number, strokes: $0.strokes) },
                    email: player.email,
                    ballColorDT: player.ballColorDT
                )
            },
            locationName: source.locationName,
            startTime: source.startTime,
            endTime: source.endTime
        )
    }
}
