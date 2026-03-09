//
//  LeaderBoardViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//


import Foundation
import Combine

enum leaderboardSection: String, CaseIterable {
    case weekly = "Weekly"
    case allTime = "All Time"
    
    var sfSymbol: String {
        switch self {
        case .weekly:
            return "calendar.circle.fill"
        case .allTime:
            return "star.fill"
        }
    }
}

@MainActor
class LeaderBoardViewModel: ObservableObject {
    
    @Published var weeklyLeaderboard: [LeaderboardEntry] = mockWeeklyLeaderboard
    @Published var allTimeLeaderboard: [LeaderboardEntry] = mockAllTimeLeaderboard
    
    @Published var pickedSection : leaderboardSection = .allTime
    
    // MARK: - Mock Data
    private static let mockWeeklyLeaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(id: "1", userId: "user1", name: "Alex Rivera", photoURL: nil, totalStrokes: 42, email: "alex@example.com"),
        LeaderboardEntry(id: "2", userId: "user2", name: "Jordan Chen", photoURL: nil, totalStrokes: 45, email: "jordan@example.com"),
        LeaderboardEntry(id: "3", userId: "user3", name: "Sam Morrison", photoURL: nil, totalStrokes: 47, email: "sam@example.com"),
        LeaderboardEntry(id: "4", userId: "user4", name: "Casey Taylor", photoURL: nil, totalStrokes: 48, email: "casey@example.com"),
        LeaderboardEntry(id: "5", userId: "user5", name: "Morgan Price", photoURL: nil, totalStrokes: 50, email: "morgan@example.com"),
        LeaderboardEntry(id: "6", userId: "user6", name: "Riley White", photoURL: nil, totalStrokes: 51, email: "riley@example.com"),
        LeaderboardEntry(id: "7", userId: "user7", name: "Dakota Adams", photoURL: nil, totalStrokes: 52, email: "dakota@example.com"),
        LeaderboardEntry(id: "8", userId: "user8", name: "Blake Thompson", photoURL: nil, totalStrokes: 54, email: "blake@example.com"),
        LeaderboardEntry(id: "9", userId: "user9", name: "Harper Martinez", photoURL: nil, totalStrokes: 55, email: "harper@example.com"),
        LeaderboardEntry(id: "10", userId: "user10", name: "Cameron Scott", photoURL: nil, totalStrokes: 56, email: "cameron@example.com"),
        LeaderboardEntry(id: "11", userId: "user11", name: "Phoenix Green", photoURL: nil, totalStrokes: 57, email: "phoenix@example.com"),
        LeaderboardEntry(id: "12", userId: "user12", name: "Sage Anderson", photoURL: nil, totalStrokes: 58, email: "sage@example.com"),
        LeaderboardEntry(id: "13", userId: "user13", name: "Austin Davis", photoURL: nil, totalStrokes: 59, email: "austin@example.com"),
        LeaderboardEntry(id: "14", userId: "user14", name: "Quinn Nelson", photoURL: nil, totalStrokes: 60, email: "quinn@example.com"),
        LeaderboardEntry(id: "15", userId: "user15", name: "Reese Murphy", photoURL: nil, totalStrokes: 61, email: "reese@example.com"),
        LeaderboardEntry(id: "16", userId: "user16", name: "Skylar Patel", photoURL: nil, totalStrokes: 62, email: "skylar@example.com"),
        LeaderboardEntry(id: "17", userId: "user17", name: "Taylor Jackson", photoURL: nil, totalStrokes: 63, email: "taylor@example.com"),
        LeaderboardEntry(id: "18", userId: "user18", name: "Parker King", photoURL: nil, totalStrokes: 64, email: "parker@example.com"),
        LeaderboardEntry(id: "19", userId: "user19", name: "Avery Wright", photoURL: nil, totalStrokes: 65, email: "avery@example.com"),
        LeaderboardEntry(id: "20", userId: "user20", name: "Jordan Lopez", photoURL: nil, totalStrokes: 66, email: "jordan.l@example.com"),
        LeaderboardEntry(id: "21", userId: "user21", name: "Casey Hill", photoURL: nil, totalStrokes: 67, email: "casey.h@example.com"),
        LeaderboardEntry(id: "22", userId: "user22", name: "Morgan Scott", photoURL: nil, totalStrokes: 68, email: "morgan.s@example.com"),
        LeaderboardEntry(id: "23", userId: "user23", name: "Riley Green", photoURL: nil, totalStrokes: 69, email: "riley.g@example.com"),
        LeaderboardEntry(id: "24", userId: "user24", name: "Dakota Blue", photoURL: nil, totalStrokes: 70, email: "dakota.b@example.com"),
        LeaderboardEntry(id: "25", userId: "user25", name: "Blake Knight", photoURL: nil, totalStrokes: 71, email: "blake.k@example.com"),
    ]
    
    private static let mockAllTimeLeaderboard: [LeaderboardEntry] = [
        LeaderboardEntry(id: "1", userId: "user1", name: "Alex Rivera", photoURL: nil, totalStrokes: 38, email: "alex@example.com"),
        LeaderboardEntry(id: "2", userId: "user2", name: "Jordan Chen", photoURL: nil, totalStrokes: 41, email: "jordan@example.com"),
        LeaderboardEntry(id: "3", userId: "user3", name: "Sam Morrison", photoURL: nil, totalStrokes: 43, email: "sam@example.com"),
        LeaderboardEntry(id: "4", userId: "user4", name: "Casey Taylor", photoURL: nil, totalStrokes: 44, email: "casey@example.com"),
        LeaderboardEntry(id: "5", userId: "user5", name: "Morgan Price", photoURL: nil, totalStrokes: 46, email: "morgan@example.com"),
        LeaderboardEntry(id: "6", userId: "user6", name: "Riley White", photoURL: nil, totalStrokes: 47, email: "riley@example.com"),
        LeaderboardEntry(id: "7", userId: "user7", name: "Dakota Adams", photoURL: nil, totalStrokes: 48, email: "dakota@example.com"),
        LeaderboardEntry(id: "8", userId: "user8", name: "Blake Thompson", photoURL: nil, totalStrokes: 50, email: "blake@example.com"),
        LeaderboardEntry(id: "9", userId: "user9", name: "Harper Martinez", photoURL: nil, totalStrokes: 51, email: "harper@example.com"),
        LeaderboardEntry(id: "10", userId: "user10", name: "Cameron Scott", photoURL: nil, totalStrokes: 52, email: "cameron@example.com"),
        LeaderboardEntry(id: "11", userId: "user11", name: "Phoenix Green", photoURL: nil, totalStrokes: 53, email: "phoenix@example.com"),
        LeaderboardEntry(id: "12", userId: "user12", name: "Sage Anderson", photoURL: nil, totalStrokes: 54, email: "sage@example.com"),
        LeaderboardEntry(id: "13", userId: "user13", name: "Austin Davis", photoURL: nil, totalStrokes: 55, email: "austin@example.com"),
        LeaderboardEntry(id: "14", userId: "user14", name: "Quinn Nelson", photoURL: nil, totalStrokes: 56, email: "quinn@example.com"),
        LeaderboardEntry(id: "15", userId: "user15", name: "Reese Murphy", photoURL: nil, totalStrokes: 57, email: "reese@example.com"),
        LeaderboardEntry(id: "16", userId: "user16", name: "Skylar Patel", photoURL: nil, totalStrokes: 58, email: "skylar@example.com"),
        LeaderboardEntry(id: "17", userId: "user17", name: "Taylor Jackson", photoURL: nil, totalStrokes: 59, email: "taylor@example.com"),
        LeaderboardEntry(id: "18", userId: "user18", name: "Parker King", photoURL: nil, totalStrokes: 60, email: "parker@example.com"),
        LeaderboardEntry(id: "19", userId: "user19", name: "Avery Wright", photoURL: nil, totalStrokes: 61, email: "avery@example.com"),
        LeaderboardEntry(id: "20", userId: "user20", name: "Jordan Lopez", photoURL: nil, totalStrokes: 62, email: "jordan.l@example.com"),
        LeaderboardEntry(id: "21", userId: "user21", name: "Casey Hill", photoURL: nil, totalStrokes: 63, email: "casey.h@example.com"),
        LeaderboardEntry(id: "22", userId: "user22", name: "Morgan Scott", photoURL: nil, totalStrokes: 64, email: "morgan.s@example.com"),
        LeaderboardEntry(id: "23", userId: "user23", name: "Riley Green", photoURL: nil, totalStrokes: 65, email: "riley.g@example.com"),
        LeaderboardEntry(id: "24", userId: "user24", name: "Dakota Blue", photoURL: nil, totalStrokes: 66, email: "dakota.b@example.com"),
        LeaderboardEntry(id: "25", userId: "user25", name: "Blake Knight", photoURL: nil, totalStrokes: 67, email: "blake.k@example.com"),
    ]

}
