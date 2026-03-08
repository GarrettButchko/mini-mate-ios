//
//  Player.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//

// Models.swift
import Foundation
import SwiftData

@Model
final class Player: Identifiable, Equatable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var userId: String
    var inGame: Bool = false
    var name: String
    var photoURL: URL?
    var email: String?
    var ballColorDT: String? = nil

    @Relationship(deleteRule: .nullify)
    var game: Game?

    @Relationship(deleteRule: .cascade, inverse: \Hole.player)
    var holes: [Hole] = []

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        photoURL: URL? = nil,
        inGame: Bool = false,
        holes: [Hole] = [],
        email: String? = nil,
        ballColorDT: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.photoURL = photoURL
        self.inGame = inGame
        self.holes = holes
        self.email = email
        self.ballColorDT = ballColorDT
    }
}

extension Player {
    // Computed property: sum of strokes across all holes
    var totalStrokes: Int {
        holes.reduce(0) { $0 + $1.strokes }
    }
    
    var incomplete: Bool {
        holes.contains { $0.strokes == 0 }
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }

    func toDTO() -> PlayerDTO {
        return PlayerDTO(
            id: id,
            userId: userId,
            name: name,
            photoURL: photoURL,
            totalStrokes: totalStrokes,
            inGame: inGame,
            holes: holes.map { $0.toDTO() },
            email: email,
            ballColorDT: ballColorDT
        )
    }

    static func fromDTO(_ dto: PlayerDTO) -> Player {
        return Player(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            photoURL: dto.photoURL,
            inGame: dto.inGame,
            holes: dto.holes.map { Hole.fromDTO($0) },
            email: dto.email,
            ballColorDT: dto.ballColorDT
        )
    }
}
