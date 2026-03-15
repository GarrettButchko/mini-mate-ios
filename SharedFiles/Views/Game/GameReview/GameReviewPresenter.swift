//
//  GameReviewPresenter.swift
//  MiniMate
//
//  Created by GitHub Copilot on 2026-03-13.
//

import Foundation

struct GameReviewPresenter {
    let game: Game
    let course: Course?

    var holeCount: Int {
        if (course?.customPar) != nil {
            return game.numberOfHoles
        } else {
            return course?.numHoles ?? 18
        }
    }

    var shouldShowCustomAd: Bool? {
        return course?.customAdActive
    }

    var shareText: String {
        var lines = ["MiniMate Scorecard",
                     "Date: \(game.date.formatted(.dateTime))",
                     ""]
        
        for player in game.players {
            var holeLine = ""
            
            for hole in player.holes {
                holeLine += "|\(hole.strokes)"
            }
            
            lines.append("\(player.name): \(player.totalStrokes) strokes (\(player.totalStrokes))")
            lines.append("Holes " + holeLine)
            
        }
        lines.append("")
        lines.append("Download MiniMate: https://apps.apple.com/app/id6745438125")
        return lines.joined(separator: "\n")
    }

    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    func averageStrokes() -> [Hole] {
        let holeCount   = game.numberOfHoles
        let playerCount = game.players.count
        guard playerCount > 0 else { return [] }
        
        var sums = [Int](repeating: 0, count: holeCount)
        for player in game.players {
            for hole in player.holes {
                let idx = hole.number - 1
                sums[idx] += hole.strokes
            }
        }
        
        return sums.enumerated().map { (idx, total) in
            let avg = total / playerCount
            return Hole(number: idx + 1, strokes: avg)
        }
    }
}
