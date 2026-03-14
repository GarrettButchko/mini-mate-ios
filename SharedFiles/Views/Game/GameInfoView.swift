//
//  GameInfoReviewView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/28/25.
//


import SwiftUI

/// Displays and allows editing of the current user's profile
struct GameInfoView: View {
    // The ViewModel now holds the presentation logic.
    // The view creates and owns its ViewModel.
    @StateObject private var viewModel: GameInfoViewModel
    
    @Binding var isSheetPresent: Bool

    // The initializer now takes the raw `Game` model and uses it
    // to create the ViewModel.
    init(game: Game, isSheetPresent: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: GameInfoViewModel(game: game))
        _isSheetPresent = isSheetPresent
    }

    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)

                HStack {
                    Text("Game Info")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                }

                List {
                    Section ("Info") {
                        // The view now uses the pre-formatted properties from the ViewModel.
                        // No more logic (like string interpolation, nil-coalescing, or formatting) in the View.
                        UserInfoRow(label: "Game ID/Code", value: viewModel.gameId)
                        UserInfoRow(label: "Number of players", value: viewModel.playerCount)
                        UserInfoRow(label: "Number of holes", value: viewModel.holeCount)
                        UserInfoRow(label: "Date Started", value: viewModel.dateStarted)
                        UserInfoRow(label: "Location", value: viewModel.location)
                        UserInfoRow(label: "Course ID", value: viewModel.courseId)
                    }
                }
            }
        }
    }
}
