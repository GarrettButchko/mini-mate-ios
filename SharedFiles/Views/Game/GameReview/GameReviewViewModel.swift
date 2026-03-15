//
//  GameReviewViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class GameReviewViewModel: ObservableObject {
    @Published var course: Course?
    
    let game: Game
    
    var presenter: GameReviewPresenter {
        GameReviewPresenter(game: game, course: course)
    }
    
    init(game: Game) {
        self.game = game
    }

    func loadCourse() async {
        guard let id = game.courseID else { return }
        
            course = await CourseRepository().fetchCourse(id: id)
        
    }
}
