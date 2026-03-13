//
//  LeaderBoardViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 3/9/26.
//


import Foundation
import Combine

@MainActor
class LeaderBoardViewModel: ObservableObject {
    
    @Published var allTimeLeaderboard: [LeaderboardEntry] = []
    
    let LBRepo = CourseLeaderboardRepository()
    
    // MARK: - Mock Data
    
    func onAppear(courseID: String) {
        // Start listening. The closure will fire immediately with existing data,
        // then again whenever data changes.
        LBRepo.listenTopAllTime(
            courseID: courseID
        ) { [weak self] entries in
            self?.allTimeLeaderboard = entries
        }
    }

    // ALWAYS do this to prevent memory leaks and unnecessary Firebase costs
    func onDisappear() {
        LBRepo.stopListening()
    }
    
    func deletePlayerEntry(courseID: String, playerID: String) {
        LBRepo.deleteEntry(courseID: courseID, playerID: playerID){ _ in }
        allTimeLeaderboard.removeAll { $0.id == playerID }
    }
}
